import asyncio, json, websockets

async def test():
    uri = "ws://127.0.0.1:8000/api/v1/ws/prices"
    async with websockets.connect(uri) as ws:
        for i in range(3):
            msg = await ws.recv()
            data = json.loads(msg)
            msg_type = data["type"]
            print(f"Frame {i+1}: type={msg_type}")
            if msg_type == "price_update":
                for p in data["data"]:
                    sym = p["symbol"]
                    price = p["price"]
                    print(f"  {sym}: {price}")
    print("WebSocket test PASSED")

asyncio.run(test())
