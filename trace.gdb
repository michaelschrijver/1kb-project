set architecture i8086
target remote localhost:1234
set $lasteip = 0
while $eip != 0x131a
    set $lasteip = $eip
    info registers
    x/i (($cs << 4) + $eip)
    stepi
end
