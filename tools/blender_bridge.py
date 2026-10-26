import socket
import json
import sys
import os

PORT = 9876
HOST = '127.0.0.1'

def send_code(code_str: str) -> dict:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(60) # Generous timeout for asset generation & GLB exports
    try:
        s.connect((HOST, PORT))
        payload = json.dumps({"type": "execute_code", "params": {"code": code_str}})
        s.sendall(payload.encode('utf-8'))
        
        # Read response buffer
        chunks = []
        while True:
            chunk = s.recv(8192)
            if not chunk:
                break
            chunks.append(chunk)
            # Try to see if valid json received
            data = b"".join(chunks)
            try:
                res = json.loads(data.decode('utf-8'))
                return res
            except:
                continue
        return {"status": "error", "message": "Connection closed before complete JSON"}
    except Exception as e:
        return {"status": "error", "message": str(e)}
    finally:
        s.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: blender_bridge.py <script_file.py>")
        sys.exit(1)
        
    script_path = sys.argv[1]
    with open(script_path, "r", encoding="utf-8") as f:
        code = f.read()
        
    res = send_code(code)
    print(json.dumps(res, indent=2))
