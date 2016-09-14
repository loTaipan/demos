# ref.: https://www.thethingsnetwork.org/forum/t/ttn-microclient/2680/4
# ref.: http://stackoverflow.com/questions/22495861/plotting-serial-data-in-python-how-to-pause-matplotlib-figure

import json
import paho.mqtt.client as mqtt
import numpy as np
from matplotlib import pyplot as plt

GRAPH_TITLE = "Limmat F\u00fchler"
GRAPH_LABEL_X = "time [samples]"
GRAPH_LABEL_Y = "temp [\N{DEGREE SIGN}C]"

MQTT_USER = "70B3D57ED0000DC2"
MQTT_PW = "1iULIOYIWsd1Wn2KSRxAzE5m0Xfv17dyo0/D/duktEM="
MQTT_BROKER = "staging.thethingsnetwork.org"
MQTT_PORT = 1883

TEMP_INIT = 20.0
TEMP_MIN = 10.0
TEMP_MAX = 40.0
TEMP_COUNT = 100

fig = 0
xdata = 0
line = 0

# gives connection message
def on_connect( client, userdata, rc ):
    print( "Connected with result code: " + str( rc ) )
    # subscribe for all devices of user
    client.subscribe( '+/devices/+/up' )

# gives message from device
def on_message( client, userdata, msg ):
	payload = msg.payload.decode( 'UTF-8' )
	#print( "Topic",msg.topic + "\nMessage: " + payload )
	
	data = json.loads( payload )
	fields = data["fields"]
	value = fields["temperature"]
	print( "Temperature: %.2f \N{DEGREE SIGN}C " % value )
	
	ydata.append( value )
	del ydata[0]
	plot_update()

def on_log( client, userdata, level, buf ):
    print( "message:" + str( buf ) )
    print( "userdata:" + str( userdata ) )

# add sample value to plot
def plot_update():
	global xdata
	global line
	line.set_xdata( np.arange( len( ydata ) ) )
	line.set_ydata( ydata )  # update the data

# redraw plot
def plot_render():
	plt.draw() # update the plot
	plt.pause( 0.000001 ) # Note this correction!


if __name__ == '__main__':
	
	# setting up MQTT client
	mqttc= mqtt.Client()
	mqttc.on_connect=on_connect
	mqttc.on_message=on_message

	mqttc.username_pw_set( MQTT_USER, MQTT_PW )
	mqttc.connect( MQTT_BROKER, MQTT_PORT, 10 )

	# setting up the animated plot
	plt.ion() # set plot to animated
	fig = plt.figure()

	ydata = [TEMP_INIT] * TEMP_COUNT
	ax1 = plt.axes() 
	
	ax1.set_title( GRAPH_TITLE )
	ax1.set_xlabel( GRAPH_LABEL_X )
	ax1.set_ylabel( GRAPH_LABEL_Y ) 
	
	line, = plt.plot(ydata)
	plt.ylim( [TEMP_MIN, TEMP_MAX] ) # y range
	
	line.set_xdata( np.arange( len( ydata ) ) )
	plot_update()
	
	# listen to server and redraw plot
	rc = 0
	while rc == 0:
		rc = mqttc.loop()
		plot_render()
