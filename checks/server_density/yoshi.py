"""
Unix system checks.
"""
# stdlib
import platform
import re
import string
import sys
import time

# project
from checks import Check
from utils.subprocess_output import subprocess

# locale-resilient float converter
to_float = lambda s: float(s.replace(",", "."))

pythonVersion = platform.python_version_tuple()
python24 = platform.python_version().startswith('2.4')

class Identifier(Check):

    def __init__(self, logger):
        Check.__init__(self, logger)
        self.header_re = re.compile(r'([%\\/\-_a-zA-Z0-9]+)[\s+]?')
        self.item_re = re.compile(r'^([a-zA-Z0-9\/]+)')
        self.value_re = re.compile(r'\d+\.\d+')

    def check(self, agentConfig):
        return {"sdAgentVersion": 2.0}


class NetworkTraffic(Check):

    def __init__(self, logger):
        Check.__init__(self, logger)
        self.header_re = re.compile(r'([%\\/\-_a-zA-Z0-9]+)[\s+]?')
        self.item_re = re.compile(r'^([a-zA-Z0-9\/]+)')
        self.value_re = re.compile(r'\d+\.\d+')

    def check(self, agentConfig):
        """Capture io stats.

        @rtype dict
        @return {"device": {"metric": value, "metric": value}, ...}
        """

        network_traffic = {}

        if sys.platform == 'linux2':
            self.logger.debug('getNetworkTraffic: linux2')

            try:
                self.logger.debug('getNetworkTraffic: attempting open')
                proc = open('/proc/net/dev', 'r')
                lines = proc.readlines()
                proc.close()

            except IOError, e:
                self.logger.error('getNetworkTraffic: exception = %s', e)
                return False

            self.logger.debug('getNetworkTraffic: open success, parsing')

            columnLine = lines[1]
            _, receiveCols, transmitCols = columnLine.split('|')
            receiveCols = map(lambda a: 'recv_' + a, receiveCols.split())
            transmitCols = map(lambda a: 'trans_' + a, transmitCols.split())

            cols = receiveCols + transmitCols
            self.logger.debug('getNetworkTraffic: parsing, looping')

            faces = {}
            for line in lines[2:]:
                if line.find(':') < 0:
                    continue
                face, data = line.split(':')
                faceData = dict(zip(cols, data.split()))
                faces[face] = faceData

            self.logger.debug('getNetworkTraffic: parsed, looping')

            interfaces = {}

            # Now loop through each interface
            for face in faces:
                key = face.strip()

                # We need to work out the traffic since the last check so first time we store the current value
                # then the next time we can calculate the difference
                try:
                    if key in network_traffic:
                        interfaces[key] = {}
                        interfaces[key]['recv_bytes'] = long(faces[face]['recv_bytes']) - long(network_traffic[key]['recv_bytes'])
                        interfaces[key]['trans_bytes'] = long(faces[face]['trans_bytes']) - long(network_traffic[key]['trans_bytes'])

                        if interfaces[key]['recv_bytes'] < 0:
                            interfaces[key]['recv_bytes'] = long(faces[face]['recv_bytes'])

                        if interfaces[key]['trans_bytes'] < 0:
                            interfaces[key]['trans_bytes'] = long(faces[face]['trans_bytes'])

                        interfaces[key]['recv_bytes'] = str(interfaces[key]['recv_bytes'])
                        interfaces[key]['trans_bytes'] = str(interfaces[key]['trans_bytes'])

                        # And update the stored value to subtract next time round
                        network_traffic[key]['recv_bytes'] = faces[face]['recv_bytes']
                        network_traffic[key]['trans_bytes'] = faces[face]['trans_bytes']

                    else:
                        network_traffic[key] = {}
                        network_traffic[key]['recv_bytes'] = faces[face]['recv_bytes']
                        network_traffic[key]['trans_bytes'] = faces[face]['trans_bytes']

                    # Logging
                    self.logger.debug('getNetworkTraffic: %s = %s', key, network_traffic[key]['recv_bytes'])
                    self.logger.debug('getNetworkTraffic: %s = %s', key, network_traffic[key]['trans_bytes'])

                except KeyError:
                    self.logger.error('getNetworkTraffic: no data for %s', key)

                except ValueError:
                    self.logger.error('getNetworkTraffic: invalid data for %s', key)

            self.logger.debug('getNetworkTraffic: completed, returning')
            self.logger.debug('getNetworkTraffic: completed, returning %s' % (str(network_traffic)))

            return {'networkTraffic': network_traffic}


class CPUStats(Check):

    def __init__(self, logger):
        Check.__init__(self, logger)
        self.header_re = re.compile(r'([%\\/\-_a-zA-Z0-9]+)[\s+]?')
        self.item_re = re.compile(r'^([a-zA-Z0-9\/]+)')
        self.value_re = re.compile(r'\d+\.\d+')

    def check(self, agentConfig):
        self.logger.debug('getCPUStats: start')

        cpu_stats = {}

        if sys.platform == 'linux2':
            self.logger.debug('getCPUStats: linux2')

            headerRegexp = re.compile(r'.*?([%][a-zA-Z0-9]+)[\s+]?')
            itemRegexp = re.compile(r'.*?\s+(\d+)[\s+]?')
            valueRegexp = re.compile(r'\d+\.\d+')
            proc = None
            try:
                proc = subprocess.Popen(['mpstat', '-P', 'ALL', '1', '1'], stdout=subprocess.PIPE, close_fds=True)
                stats = proc.communicate()[0]

                if int(pythonVersion[1]) >= 6:
                    try:
                        proc.kill()
                    except Exception:
                        self.logger.debug('Process already terminated')

                stats = stats.split('\n')
                header = stats[2]
                headerNames = re.findall(headerRegexp, header)
                device = None

                for statsIndex in range(3, len(stats)):
                    row = stats[statsIndex]

                    if not row:  # skip the averages
                        break

                    deviceMatch = re.match(itemRegexp, row)

                    if string.find(row, 'all') is not -1:
                        device = 'ALL'
                    elif deviceMatch is not None:
                        device = 'CPU%s' % deviceMatch.groups()[0]

                    values = re.findall(valueRegexp, row.replace(',', '.'))

                    cpu_stats[device] = {}
                    for headerIndex in range(0, len(headerNames)):
                        headerName = headerNames[headerIndex]
                        cpu_stats[device][headerName] = values[headerIndex]

            except OSError:
                # we dont have it installed return nothing
                return False

            except Exception:
                import traceback
                self.logger.error("getCPUStats: exception = %s", traceback.format_exc())

                if int(pythonVersion[1]) >= 6:
                    try:
                        if proc is not None:
                            proc.kill()
                    except UnboundLocalError:
                        self.logger.debug('Process already terminated')
                    except Exception:
                        self.logger.debug('Process already terminated')

                return False

        elif sys.platform == 'darwin':
            self.logger.debug('getCPUStats: darwin')

            try:
                proc = subprocess.Popen(['sar', '-u', '1', '2'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
                stats = proc.communicate()[0]

                itemRegexp = re.compile(r'\s+(\d+)[\s+]?')
                titleRegexp = re.compile(r'.*?([%][a-zA-Z0-9]+)[\s+]?')
                titles = []
                values = []
                for line in stats.split('\n'):
                    # top line with the titles in
                    if '%' in line:
                        titles = re.findall(titleRegexp, line)
                    if line and line.startswith('Average:'):
                        values = re.findall(itemRegexp, line)

                if values and titles:
                    cpu_stats['CPUs'] = dict(zip(titles, values))

            except Exception:
                import traceback
                self.logger.error('getCPUStats: exception = %s', traceback.format_exc())
                return False

        else:
            self.logger.debug('getCPUStats: unsupported platform')
            return False

        self.logger.debug('getCPUStats: completed, returning')
        return {'cpuStats': cpu_stats}


if __name__ == '__main__':
    # 1s loop with results
    import logging

    logging.basicConfig(level=logging.DEBUG, format='%(asctime)-15s %(message)s')
    log = logging.getLogger()
    networkTraffic = NetworkTraffic(log)
    cpu_stats = CPUStats(log)

    config = {"agent_key": "666"}

    while True:
        print("--- Network ---")
        print(networkTraffic.check(config))
        print("--- CPU Stats ---")
        print(cpu_stats.check(config))
        time.sleep(1)
