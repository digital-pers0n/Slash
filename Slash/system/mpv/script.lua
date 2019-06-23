function seg_start()
    pr = mp.get_property_number("time-pos")
    mp.osd_message("A-", 10000000)
    print("A:", pr)
end
mp.add_forced_key_binding("i", "segment_start", seg_start)

function seg_end()
    mp.set_property_bool("pause", true)
    pr = mp.get_property_number("time-pos")
    mp.osd_message("A-B", 10000000)
    print("B:", pr)
end
mp.add_forced_key_binding("o", "segment_end", seg_end)

function seg_clear()
    print("-")
    mp.osd_message("Segment Cleared")
end
mp.add_forced_key_binding("p", "segment_clear", seg_clear)

function seg_new()
    clear()
    print("+")
    mp.osd_message("Segment Added")
end
mp.add_forced_key_binding(";", "segment_new", seg_new)
