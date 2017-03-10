""" This plugin/integration exists to provide connection data, that
would otherwise be missing from the existing rabbitmq plugin.
"""

# stdlib
import urlparse

# 3p
import requests

# project
from checks import AgentCheck


class RabbitMQ(AgentCheck):

    """This check is for gathering statistics from the RabbitMQ
    Management Plugin (http://www.rabbitmq.com/management.html)
    """

    def __init__(self, name, init_config, agentConfig, instances=None):
        AgentCheck.__init__(self, name, init_config, agentConfig, instances)
        self.already_alerted = []

    def _get_config(self, instance):
        # make sure 'rabbitmq_api_url; is present
        if 'rabbitmq_api_url' not in instance:
            raise Exception('Missing "rabbitmq_api_url" in RabbitMQ config.')

        # get parameters
        base_url = instance['rabbitmq_api_url']
        if not base_url.endswith('/'):
            base_url += '/'
        username = instance.get('rabbitmq_user', 'guest')
        password = instance.get('rabbitmq_pass', 'guest')

        auth = (username, password)

        return base_url, auth

    def check(self, instance):
        base_url, auth = self._get_config(instance)

        # Generate metrics from the connections API.
        self.get_stats(instance, base_url, 'connections', auth=auth)


    def _get_data(self, url, auth=None):
        try:
            r = requests.get(url, auth=auth)
            r.raise_for_status()
            data = r.json()
        except requests.exceptions.HTTPError as e:
            raise Exception(
                'Cannot open RabbitMQ API url: %s %s' % (url, str(e)))
        except ValueError, e:
            raise Exception(
                'Cannot parse JSON response from API url: %s %s' % (url, str(e)))
        return data

    def get_stats(self, instance, base_url, object_type, auth=None):
        """
        instance: the check instance
        base_url: the url of the rabbitmq management api (e.g. http://localhost:15672/api)
        object_type: either QUEUE_TYPE or NODE_TYPE
        max_detailed: the limit of objects to collect for this type
        filters: explicit or regexes filters of specified queues or nodes (specified in the yaml file)
        """

        data = self._get_data(
            urlparse.urljoin(base_url, object_type), auth=auth)

        if data:
            self.gauge('rabbitmq.connections', len(data))
