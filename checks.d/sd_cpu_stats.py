import re
import traceback

# 3p
try:
    import psutil
except ImportError:
    psutil = None

# project
import logging
import platform
import string
import subprocess
import sys
import time
from checks import AgentCheck
from utils.subprocess_output import get_subprocess_output

pythonVersion = platform.python_version_tuple()
python24 = platform.python_version().startswith('2.4')


class ServerDensityCPUChecks(AgentCheck):
    """ Collects metrics about the machine's disks. """


    def check(self, instance):
        #self.log.debug('hello')
        ##self.gauge('serverdensity.disk.free', 1)
        #self.gauge('serverdensity.disk.free', 1, device_name="/")
        #self.gauge('serverdensity.disk.free', 2, device_name="/var")
        #self.gauge('serverdensity.disk.free', 3, device_name="/home")
        #self.log.debug('hello2')

        def get_value(legend, data, name, filter_value=None):
            "Using the legend and a metric name, get the value or None from the data line"
            if name in legend:
                value = data[legend.index(name)]
                if filter_value is not None:
                    if value > filter_value:
                        return None
                return value

            else:
                # FIXME return a float or False, would trigger type error if not python
                self.log.debug("Cannot extract cpu value %s from %s (%s)" % (name, data, legend))
                return 0.0

        self.log.debug('getCPUStats: start')

        cpu_stats = {}

        if sys.platform == 'linux2':
            self.log.debug('getCPUStats: linux2')

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
                        self.log.debug('Process already terminated')

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
                        key = headerName.replace('%', '')
                        self.gauge('serverdensity.cpu.{0}'.format(key), float(values[headerIndex]), device_name=device)

            except OSError:
                # we dont have it installed return nothing
                return False

            except Exception:
                import traceback
                self.log.error("getCPUStats: exception = %s", traceback.format_exc())

                if int(pythonVersion[1]) >= 6:
                    try:
                        if proc is not None:
                            proc.kill()
                    except UnboundLocalError:
                        self.log.debug('Process already terminated')
                    except Exception:
                        self.log.debug('Process already terminated')

                return False

        elif sys.platform == 'darwin':
            self.log.debug('getCPUStats: darwin')

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
                    cpu_stats['ALL'] = dict(zip(titles, values))
                    for headerIndex in range(0, len(titles)):
                        key = titles[headerIndex].replace('%', '')
                        self.gauge('serverdensity.cpu.{0}'.format(key), float(values[headerIndex]), device_name='ALL')

            except Exception:
                import traceback
                self.log.error('getCPUStats: exception = %s', traceback.format_exc())
                return False

        elif sys.platform.startswith("freebsd"):
            # generate 3 seconds of data
            # tty            ada0              cd0            pass0             cpu
            # tin  tout  KB/t tps  MB/s   KB/t tps  MB/s   KB/t tps  MB/s  us ni sy in id
            # 0    69 26.71   0  0.01   0.00   0  0.00   0.00   0  0.00   2  0  0  1 97
            # 0    78  0.00   0  0.00   0.00   0  0.00   0.00   0  0.00   0  0  0  0 100
            iostats, _, _ = get_subprocess_output(['iostat', '-w', '3', '-c', '2'], self.log)
            lines = [l for l in iostats.splitlines() if len(l) > 0]
            legend = [l for l in lines if "us" in l]
            if len(legend) == 1:
                headers = legend[0].split()
                data = lines[-1].split()
                cpu_user = get_value(headers, data, "us")
                cpu_nice = get_value(headers, data, "ni")
                cpu_sys = get_value(headers, data, "sy")
                cpu_intr = get_value(headers, data, "in")
                cpu_idle = get_value(headers, data, "id")
                self.gauge('serverdensity.cpu.usr', float(cpu_user), device_name='ALL')
                self.gauge('serverdensity.cpu.nice', float(cpu_nice), device_name='ALL')
                self.gauge('serverdensity.cpu.sys', float(cpu_sys), device_name='ALL')
                self.gauge('serverdensity.cpu.irq', float(cpu_intr), device_name='ALL')
                self.gauge('serverdensity.cpu.idle', float(cpu_idle), device_name='ALL')
                cpu_stats['ALL'] = {
                    'usr': cpu_user,
                    'nice': cpu_nice,
                    'sys': cpu_sys,
                    'irq': cpu_intr,
                    'idle': cpu_idle,
                }

            else:
                self.logger.warn("Expected to get at least 4 lines of data from iostat instead of just " + str(iostats[:max(80, len(iostats))]))
                return False

        else:
            self.log.debug('getCPUStats: unsupported platform')
            return False

        self.log.debug('getCPUStats: completed, returning')
        return {'cpuStats': cpu_stats}


if __name__ == '__main__':

    check, _instances = ServerDensityCPUChecks.from_yaml('conf.d/sd_cpu_stats.yaml')

    root = logging.getLogger()
    root.setLevel(logging.INFO)

    ch = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)

    root.addHandler(ch)

    check.log = root
    try:
        for i in xrange(200):
            print check.check({})
            time.sleep(30)
    except Exception as e:
        print "Something broke {0}".format(traceback.format_exc())
    finally:
        check.stop()
