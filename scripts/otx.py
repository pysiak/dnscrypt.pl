#!/usr/bin/python3
import requests, json, time, datetime

apikey = ''

if apikey == '':
	quit()

date = "2000-01-01"
params = {'modified_since': date, 'types': 'domain', 'limit': 20000}
header = {'X-OTX-API-KEY': api_key}
url = 'https://otx.alienvault.com/api/v1/indicators/export'

while(not(url is None)):
	try:
		r = requests.get(url, params=params, headers=header)
		response = r.json()
		for result in response['results']:
			print(result['indicator'])

		url = response['next']
		time.sleep(0.1)
	except:
		time.sleep(1)
