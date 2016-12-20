: over swap dup rot swap ;
: tuck swap over ;
: repoutb tuck tuck outb drop ;
: outdebug 233 swap outb ;
72 outdebug
101 outdebug
108 outdebug
108 outdebug
111 outdebug
halt
