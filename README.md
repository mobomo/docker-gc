# Docker GC

Script aimed at cleaning up a docker environment, specifically for builder cases and devops agents

## Getting Started

These instructions will cover usage information

### Prerequisities

In order to run this container you'll need docker installed.

- [Windows](https://docs.docker.com/windows/started)
- [OS X](https://docs.docker.com/mac/started/)
- [Linux](https://docs.docker.com/linux/started/)

### Usage

Clean entire system without holding back

```shell
./docker-gc.sh --purge-all
```


## TODO
- Implement ability to whitelist containers to not get destroyed, ie base images, registry, etc
- Add command to help cleanup environment without destroying everything