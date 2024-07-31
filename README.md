# This project is by no means finished OR working

Branch 0.2 contains the (currently) working version, which contains a first person controller, a json based map serialization system, a DearIMGUI based Debug System, which also allows you to essently use a very simple editor system
The physiscs are almost working, at least the gravity, since for some reason the normal collision physics broke when I enabled gravity... The Controller uses a collide-and-slide collision system (at least it would, if it was working)

The Menu-UI is traversed via WASD

For the IMGUI bindings I'm using [L-4's bindings](https://gitlab.com/L-4/odin-imgui), with [lucaspoffo's raylib backend](https://gist.github.com/lucaspoffo/a0d4192acd74d718e433ea0bafe17bc4), which [I modified](https://gist.github.com/Lucky44x/cb7928ac6de7926ee1dcc1b997ce20bd) to work with the vendor binding for raylib from odin 2024-07
