import unittest
from main import app

class HelloWorldTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_hello(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode(), 'Hello, World!')

if __name__ == '__main__':
    unittest.main()
