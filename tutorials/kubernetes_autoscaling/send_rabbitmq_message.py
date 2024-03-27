import pika
import time

# Set up connection parameters
credentials = pika.PlainCredentials('user', 'PASSWORD')
parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)

# Create a new connection
connection = pika.BlockingConnection(parameters)

# Open a channel
channel = connection.channel()

# Declare a queue
channel.queue_declare(queue='hello')

# Number of messages to send
num_messages = 100000  # Adjust this number based on your test needs

# Loop to send messages
for i in range(num_messages):
    message = f'Message number {i}'
    channel.basic_publish(exchange='',
                          routing_key='hello',
                          body=message)
    print(f" [x] Sent {message}")

    # Optional: sleep for a short duration
    time.sleep(0.01)  # Adjust the sleep duration as needed

# Close the connection
connection.close()

