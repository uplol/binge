import asyncio
from typing import Any
import websockets
import orjson
import requests

# https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md
BINANCE_WSS_URL = "wss://stream.binance.com:9443/ws"

# https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#exchange-information
BINANCE_EXCHANGE_INFO_URL = "https://api.binance.com/api/v3/exchangeInfo"


async def main():

    async for websocket in websockets.connect(BINANCE_WSS_URL):

        # Build and send SUBSCRIBE payloads
        # https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md#subscribe-to-a-stream
        await websocket.send(
            orjson.dumps(
                {
                    "method": "SUBSCRIBE",
                    "params": await get_usdt_trade_pairs(),
                    "id": 1,
                }
            ).decode("utf-8")
        )

        # Binance claims they disconnect every 24hrs, so let's blindly attempt to reconnect if we get disconnected
        try:
            async for message in websocket:
                await process(message)
        except websockets.ConnectionClosed as e:
            continue


async def process(message: str):
    print(message)


async def get_usdt_trade_pairs() -> list[str]:
    """
    Connects to the Binance Exchange Info endpoint to get all all symbols, which are then filtered to active trading USDT pairs

    Returns:
        list of symbol pairs formatted as `symbol@trade`
    """

    data = requests.get(BINANCE_EXCHANGE_INFO_URL).json()
    symbols = []
    for symbol in data["symbols"]:
        if (
            symbol["status"] == "TRADING"
            and symbol["isSpotTradingAllowed"]
            and symbol["quoteAsset"] == "USDT"
        ):
            symbols.append(f"{symbol['symbol'].lower()}@trade") # Note: `SYMBOL@trade` must be lowercase or the api will not return anything

    return symbols


if __name__ == "__main__":
    loop = asyncio.new_event_loop()
    loop.run_until_complete(main())
    loop.run_forever()
