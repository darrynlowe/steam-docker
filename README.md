This is a Docker container that runs Steam inside it.

It works with Remote Play using Proton 8, 9, and 10.

The key to doing this was:
- Making the container privileged
- Passing through /dev/input as a volume (and not as a device, since what happens is that a device pass through makes it a static snapshot where as remote play adds dynamically new /dev/input/eventX nodes that need a 'live' volume pass thru. This needs to be done with the right permissions.
- Removing dumb udev and passing through /run/udev from the host (linked to the point above) 

It has some additional complexity because I'm running an Nvidia 1080 Ti which is now not supported by the latest Nvidia drivers. So there's some butchery from the AUR to bring down the legacy driver set inside the container since it's needed for dependencies. This can create a situation with version mismatch with the host, so make sure the host is also up to date.

