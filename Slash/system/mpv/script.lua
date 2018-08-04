function seg_start()
    pr = mp.get_property_number("time-pos")
    mp.osd_message("Segment Start")
    mp.set_property_number("ab-loop-a", pr)
    print("A:", pr)
end
mp.add_forced_key_binding("i", "segment_start", seg_start)

function seg_end()
    pr = mp.get_property_number("time-pos")
    mp.osd_message("Segment End")
    -- mp.command("frame-back-step")
    mp.set_property_number("ab-loop-b", pr)
    mp.set_property_number("time-pos", pr - 0.05)
    print("B:", pr)
end
mp.add_forced_key_binding("o", "segment_end", seg_end)

function clear()
    mp.set_property("ab-loop-a", "no")
    mp.set_property("ab-loop-b", "no")
end

function seg_clear()
    clear()
    mp.osd_message("Segment Cleared")
end
mp.add_forced_key_binding("p", "segment_clear", seg_clear)

function seg_new()
    clear()
    print("+")
    mp.osd_message("Segment Added")
end
mp.add_forced_key_binding(";", "segment_new", seg_new)
