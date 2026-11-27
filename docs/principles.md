# Principles

**Draft.** What Callisto should be like to use and to work on. It applies to
everything: the system, the shell, the installer, updates, the repository and
its documentation. A change that goes against one of these needs a reason.

Callisto is a traditional, well-supported Debian system that behaves like a
good image-based one: it is easy to use, hard to break, and easy to maintain.

## To use

1. **Nothing ordinary needs a terminal or a config file.**
2. **Anything that can break can be undone.** Updates, settings and resets have
   a way back.
3. **No half states.** A change applies completely or not at all.
4. **It never interrupts.** Long work happens in the background and asks
   nothing midway.
5. **One way to do each thing**, and one component per job.
6. **Ours and yours stay apart.** Defaults live in `/usr`; choices live in
   `/etc` and home. An update never overwrites a choice.
7. **Failure is explained and survivable.** There is a fallback, and a plain
   message saying what happened.

## To feel

8. **Motion explains.** Nothing pops in or out, and nothing makes you wait for
   an animation.
9. **One design.** The boards and tokens cover every screen, including the
   installer, the login screen and boot.
10. **Fast enough not to notice.** Say what is measured before calling it fast.
11. **Quiet.** No nagging, and no control that does nothing.

## To build

12. **Callisto is one product with one version**, separate from Debian's.
13. **Declared, not scripted.** What is on the system can be read from files in
    this repository.
14. **The same input gives the same image**, and a build says what changed.
15. **Seeing a change is one command.**
16. **Tested as shipped.** CI builds the image and boots it; what was only
    checked by hand, or not at all, is written down.
17. **Keep it small.** One tool where one will do; delete what is not used.
18. **Documentation describes what exists.**

## Where we fall short today

| Principle | Gap |
|---|---|
| 2, 3 | No snapshots or rollback; updates are plain apt |
| 5, 17 | Our own logic is spread over Python and shell programs |
| 7 | Few failures say anything on screen; no diagnostic command |
| 9 | No boot splash or themed disk passphrase prompt |
| 10 | Boot time and memory use are not measured |
| 12 | Our files are copied into the image, so installed systems cannot get changes |
| 14 | Debian mirrors are not pinned by default |
| 15 | Trying a change on a running system means rebuilding the image or copying by hand |
| 16 | CI boots the image but does not install it or drive the desktop |

The [roadmap](roadmap.md) tracks the work.
