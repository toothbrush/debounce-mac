# debounce-mac

This is for those annoying moments when you wished that macOS had
[`XkbSetBounceKeysDelay`](https://linux.die.net/man/3/xkbsetbouncekeysdelay)
like Linux does.

This is a bog-simple keyboard event tap that intercepts any
(identical) keystrokes that happen within a configurable time window.
Magic.  [See
here](https://apple.stackexchange.com/questions/246840/debounce-mechanical-keyboard-in-os-x)
for the genesis story.

Credit where credit is due: i mostly stole this idea and sample code
off another [StackOverflow
answer](https://stackoverflow.com/questions/19646108/modify-keydown-output).

## How do?

You should be able to make this work with something like the
following:

```ShellSession
$ make
$ sudo ./debounce
```

It needs root because it intercepts keystrokes.

If you really want, you can "install" it.  Assuming that
`/usr/local/bin` is in your `$PATH` (which it is if you use Homebrew)
you can:

```ShellSession
$ make install
```

### Auto-start at login

Another [helpful
contribution](https://github.com/toothbrush/debounce-mac/issues/2),
this time from @cpouldev.  If you'd like to auto-start `debounce` at
login, you might find something like the [included LaunchAgent
configuration](./com.debounceMac.app.plist) helpful.

Put that somewhere `launchctl` can find it, like
`~/Library/LaunchAgents/com.debounceMac.app.plist`, then load the
configuration.  macOS will automatically prompt you to give `debounce`
Accessibility access, this is needed to be able to intercept and
modify keystrokes.

```ShellSession
$ launchctl load ~/Library/LaunchAgents/com.debounceMac.app.plist
```

macOS will automatically prompt you to give `debounce` Accessibility
access, this is needed to be able to intercept and modify keystrokes.
When that's done, start it.

```ShellSession
$ launchctl start com.debounceMac.app
```

To remove / uninstall completely:

```ShellSession
$ launchctl stop com.debounceMac.app
$ launchctl unload ~/Library/LaunchAgents/com.debounceMac.app.plist
$ rm ~/Library/LaunchAgents/com.debounceMac.app.plist
$ launchctl list
$ rm /usr/local/bin/debounce
```

### Accessibility / permissions

You might get an error something like the following, even when running
as root.

```ShellSession
$ sudo ./debounce
2019-03-03 10:47:02.194 debounce[59588:499245] Initializing an event tap.
2019-03-03 10:47:02.205 debounce[59588:499245] Unable to create event tap.  Must run as root or add Accessibility privileges to this app.
2019-03-03 10:47:02.205 debounce[59588:499245] No Event tap in place!  You will need to call listen after tapEvents to get events.
```

@DanGrayson kindly [alerted me to the
fact](https://github.com/toothbrush/debounce-mac/issues/4) that on
modern macOS, you'll need to enable universal accessibility features
to let this work.  It appears that you'll need to go to System
Preferences > Privacy > Accessibility, and grant Terminal.app
permission, not the `debounce` binary as you might expect.
