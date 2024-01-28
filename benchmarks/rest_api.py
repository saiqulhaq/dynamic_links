# @author Saiqul Haq <saiqulhaq@gmail.com>
# benchmark rest api using apache bench (ab)
# target URL http://localhost:8000/v1/shortLinks
# method POST
# payload: replace {random} with random string for every run
#   {
#     "api_key": "foo",
#     "url": "https://example.com/{random}"
#   }
from locust import HttpUser, task, between
import random
import string

class APIUser(HttpUser):
    wait_time = between(1, 2)

    @task
    def post_url(self):
        random_str = ''.join(random.choices(string.ascii_lowercase + string.digits, k=10))
        self.client.post("/v1/shortLinks", json={
            "api_key": "foo",
            "url": f"https://example.com/{random_str}"
        })
