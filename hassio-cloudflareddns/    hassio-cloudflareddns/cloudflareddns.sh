import asyncio
import logging

from aiohttp import ClientSession

_LOGGER = logging.getLogger(__name__)

API_ENDPOINT = "https://api.cloudflare.com/client/v4/"
PUBLIC_IP_CHECK_URL = "https://api.ipify.org?format=json"

class CloudflareDDNSAddon:
    def __init__(self, hass, config, loop):
        self.hass = hass
        self.config = config
        self.loop = loop

        self.api_key = config["api_key"]
        self.zone_id = config["zone_id"]
        self.record_id = config["record_id"]
        self.record_type = config["record_type"]
        self.record_name = config["record_name"]

        self.current_public_ip = None

    async def get_public_ip(self):
        try:
            async with ClientSession() as session:
                async with session.get(PUBLIC_IP_CHECK_URL) as response:
                    data = await response.json()
                    self.current_public_ip = data["ip"]
        except Exception as e:
            _LOGGER.error("Error getting public IP: %s", e)

    async def get_dns_record(self):
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            }

            async with ClientSession() as session:
                url = f"{API_ENDPOINT}zones/{self.zone_id}/dns_records/{self.record_id}"
                async with session.get(url, headers=headers) as response:
                    data = await response.json()
                    return data["result"]
        except Exception as e:
            _LOGGER.error("Error getting DNS record: %s", e)

    async def update_dns_record(self, new_ip):
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
            }
            data = {
                "type": self.record_type,
                "name": self.record_name,
                "content": new_ip,
            }

            async with ClientSession() as session:
                url = f"{API_ENDPOINT}zones/{self.zone_id}/dns_records/{self.record_id}"
                async with session.put(url, headers=headers, json=data) as response:
                    response_data = await response.json()
                    if response_data["success"]:
                        _LOGGER.info("DNS record updated successfully")
                    else:
                        _LOGGER.error("Failed to update DNS record: %s", response_data)
        except Exception as e:
            _LOGGER.error("Error updating DNS record: %s", e)

    async def check_and_update_dns(self):
        await self.get_public_ip()

        if self.current_public_ip:
            dns_record = await self.get_dns_record()

            if dns_record:
                dns_ip = dns_record["content"]

                if dns_ip != self.current_public_ip:
                    _LOGGER.info("Public IP has changed. Updating DNS record.")
                    await self.update_dns_record(self.current_public_ip)
                else:
                    _LOGGER.info("Public IP has not changed. No update needed.")
            else:
                _LOGGER.error("DNS record not found.")
        else:
            _LOGGER.error("Failed to get current public IP.")

    async def run(self):
        while True:
            await self.check_and_update_dns()
            await asyncio.sleep(self.config["update_interval"])

async def async_setup(hass, config):
    loop = hass.loop
    addon = CloudflareDDNSAddon(hass, config, loop)
    loop.create_task(addon.run())
    return True
