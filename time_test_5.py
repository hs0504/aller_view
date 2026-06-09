import random
import gevent 
from locust import HttpUser, task, between
from payloads import all_payloads

class BatchConcurrencyUser(HttpUser):
    wait_time = between(3.0 , 5.0)

    def on_start(self):
        self.payload_list = all_payloads
        self.test_count = 0
        self.max_tests = 1
        self.all_completed = False

    def send_single_request(self, payload):
        with self.client.post("/api/analyze-menu", json=payload, catch_response=True) as response:
            if response.status_code == 200:
                try:
                    res_json = response.json()
                    if res_json.get("status") == "success":
                        response.success()
                    else:
                        response.failure(f"AI Logic Error: {res_json.get('error_message')}")
                except Exception as e:
                    response.failure(f"JSON Parse Error: {str(e)}")
            else:
                response.failure(f"HTTP Error {response.status_code}")

    @task
    def execute_batch(self):
        if self.test_count >= self.max_tests:
            if not self.all_completed:
                print("1세트(총 5개) 동시 요청 테스트가 모두 완료되었습니다.")
                self.all_completed = True
                self.environment.runner.quit()
            return

        selected_payloads = random.sample(self.payload_list, 5)
        
        print(f"[{self.test_count + 1}/2] 5명 동시 출발 (DB 타격 시작!)...")
        
        greenlets = [gevent.spawn(self.send_single_request, p) for p in selected_payloads]
        
        gevent.joinall(greenlets)
        
        print(f"[{self.test_count + 1}/2] 5명 모두 결승선 통과. 다음 세트 준비 중...")
        self.test_count += 1