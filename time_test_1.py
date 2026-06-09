from locust import HttpUser, task, between
from payloads import all_payloads

class MenuTestSuiteUser(HttpUser):
    wait_time = between(7.0 , 8.0)

    def on_start(self):
        self.payload_list = all_payloads
        self.current_index = 0
        self.all_sent = False

    @task
    def mock_menu_analysis(self):
        if self.current_index >= len(self.payload_list):
            if not self.all_sent:
                print("모든 테스트 데이터 전송 완료.")
                self.all_sent = True
                self.environment.runner.quit() 
            return

        selected_payload = self.payload_list[self.current_index]
        
        with self.client.post("/api/analyze-menu", json=selected_payload, catch_response=True) as response:
            if response.status_code == 200:
                try:
                    res_json = response.json()
                    if res_json.get("status") == "success":
                        response.success()
                    else:
                        response.failure(f"AI Business Logic Error: {res_json.get('error_message')}")
                except Exception as parse_err:
                    response.failure(f"JSON 파싱 실패: {parse_err}")
            else:
                response.failure(f"HTTP Server Error: {response.status_code}")
        
        self.current_index += 1