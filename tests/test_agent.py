import unittest

try:
    import agent
except SystemExit:
    pass # expected, agent.py line 209. Must be fixed to add new tests.


class AgentTest(unittest.TestCase):

    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_empy(self):
        """Don't test anything yet."""
        pass


def main():
    unittest.main()

if __name__ == '__main__':
    main()
