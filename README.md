# Type and Learn WebSockets

[The main project page](https://github.com/tothpeter/type_and_learn)

This is a lightweight rack based micro service using Puma application server. This project is a part of my home project called Type and Learn.

Its duty is:
- to receive and handle subscription messages for a certain event from the browser via web sockets
- to receive and handle event messages from other internal processes via unix sockets
- and after all send the right event to the right browser


## Run in production
```
rackup -s puma -E production
```
--or--
```
bundle exec puma
```

## Run without production config
```
bundle exec puma -C -
```

## Ruby version
2.2.3

## How to run the test suite
```
bundle exec rspec
```