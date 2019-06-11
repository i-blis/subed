(add-to-list 'load-path "./subed")
(require 'subed)

(defvar mock-srt-data
  "1
00:01:01,000 --> 00:01:05,123
Foo.

2
00:02:02,234 --> 00:02:10,345
Bar.

3
00:03:03,456 --> 00:03:15,567
Baz.
")

(describe "Getting"
          (describe "the subtitle ID"
                    (it "returns the subtitle ID if it can be found."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 2)
                          (expect (subed-srt--subtitle-id) :to-equal 2)))
                    (it "returns nil if no subtitle ID can be found."
                        (with-temp-buffer
                          (expect (subed-srt--subtitle-id) :to-equal nil)))
                    )
          (describe "the subtitle ID at playback time"
                    (it "returns subtitle ID if time is equal to start time."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (cl-loop for target-id from 1 to 3 do
                                   (let ((msecs (subed-srt--subtitle-msecs-start target-id)))
                                     (cl-loop for outset-id from 1 to 3 do
                                              (progn
                                                (subed-srt-move-to-subtitle-id outset-id)
                                                (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal target-id)))))))
                    (it "returns subtitle ID if time is equal to stop time."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (cl-loop for target-id from 1 to 3 do
                                   (let ((msecs (subed-srt--subtitle-msecs-stop target-id)))
                                     (cl-loop for outset-id from 1 to 3 do
                                              (progn
                                                (subed-srt-move-to-subtitle-id outset-id)
                                                (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal target-id)))))))
                    (it "returns subtitle ID if time is between start and stop time."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (cl-loop for target-id from 1 to 3 do
                                   (let ((msecs (+ 1 (subed-srt--subtitle-msecs-start target-id))))
                                     (cl-loop for outset-id from 1 to 3 do
                                              (progn
                                                (subed-srt-move-to-subtitle-id outset-id)
                                                (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal target-id)))))))
                    (it "returns first subtitle ID if time is before the first subtitle's start time."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (let ((msecs (- (save-excursion
                                            (goto-char (point-min))
                                            (subed-srt--subtitle-msecs-start)) 1)))
                            (cl-loop for outset-id from 1 to 3 do
                                     (progn
                                       (subed-srt-move-to-subtitle-id outset-id)
                                       (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal 1))))))
                    (it "returns last subtitle ID if time is after last subtitle's start time."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (let ((msecs (+ (save-excursion
                                            (goto-char (point-max))
                                            (subed-srt--subtitle-msecs-stop)) 1)))
                            (cl-loop for outset-id from 1 to 3 do
                                     (progn
                                       (subed-srt-move-to-subtitle-id outset-id)
                                       (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal 3))))))
                    (it "returns previous subtitle ID when time is between subtitles."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (cl-loop for target-id from 1 to 2 do
                                   (let ((msecs (+ (subed-srt--subtitle-msecs-stop target-id) 1)))
                                     (cl-loop for outset-id from 1 to 3 do
                                              (progn
                                                (subed-srt-move-to-subtitle-id outset-id)
                                                (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal target-id))))
                                   (let ((msecs (- (subed-srt--subtitle-msecs-start (+ target-id 1)) 1)))
                                     (cl-loop for outset-id from 1 to 3 do
                                              (progn
                                                (subed-srt-move-to-subtitle-id outset-id)
                                                (expect (subed-srt--subtitle-id-at-msecs msecs) :to-equal target-id)))))))
                    )
          (describe "the subtitle start/stop time"
                    (it "returns the time in milliseconds."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 2)
                          (expect (subed-srt--subtitle-msecs-start) :to-equal (+ (* 2 60000) (* 2 1000) 234))
                          (expect (subed-srt--subtitle-msecs-stop) :to-equal (+ (* 2 60000) (* 10 1000) 345))))
                    (it "returns nil if time can't be found."
                        (with-temp-buffer
                          (expect (subed-srt--subtitle-msecs-start) :to-be nil)
                          (expect (subed-srt--subtitle-msecs-stop) :to-be nil)))
                    )
          (describe "the subtitle text"
                    (describe "when text is empty"
                              (it "and at the beginning with a trailing newline."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 1)
                                    (kill-line)
                                    (expect (subed-srt--subtitle-text) :to-equal "")))
                              (it "and at the beginning without a trailing newline."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 1)
                                    (kill-whole-line)
                                    (expect (subed-srt--subtitle-text) :to-equal "")))
                              (it "and in the middle."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 2)
                                    (kill-line)
                                    (expect (subed-srt--subtitle-text) :to-equal "")))
                              (it "and at the end with a trailing newline."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 3)
                                    (kill-line)
                                    (expect (subed-srt--subtitle-text) :to-equal "")))
                              (it "and at the end without a trailing newline."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 3)
                                    (kill-whole-line)
                                    (expect (subed-srt--subtitle-text) :to-equal "")))
                              )
                    (describe "when text is not empty"
                              (it "and has no linebreaks."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 2)
                                    (expect (subed-srt--subtitle-text) :to-equal "Bar.")))
                              (it "and has linebreaks."
                                  (with-temp-buffer
                                    (insert mock-srt-data)
                                    (subed-srt-move-to-subtitle-text 2)
                                    (insert "Bar.\n")
                                    (expect (subed-srt--subtitle-text) :to-equal "Bar.\nBar.")))
                              )
                    )
          (describe "the point within the subtitle"
                    (it "returns the relative point if we can find an ID."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 2)
                          (expect (subed-srt--subtitle-relative-point) :to-equal 0)
                          (forward-line)
                          (expect (subed-srt--subtitle-relative-point) :to-equal 2)
                          (forward-line)
                          (expect (subed-srt--subtitle-relative-point) :to-equal 32)
                          (forward-char)
                          (expect (subed-srt--subtitle-relative-point) :to-equal 33)
                          (forward-line)
                          (expect (subed-srt--subtitle-relative-point) :to-equal 37)
                          (forward-line)
                          (expect (subed-srt--subtitle-relative-point) :to-equal 0)))
                    (it "returns nil if we can't find an ID."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 1)
                          (insert "foo")
                          (expect (subed-srt--subtitle-relative-point) :to-equal nil)))
                    )
          )

(describe "Moving"
          (describe "to current subtitle ID"
                    (it "returns ID's point when point is already on the ID."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal 1)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    (it "returns ID's point when point is on the duration."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (search-backward ",234")
                          (expect (thing-at-point 'word) :to-equal "02")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal 39)
                          (expect (thing-at-point 'word) :to-equal "2")))
                    (it "returns ID's point when point is on the text."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (search-backward "Baz.")
                          (expect (thing-at-point 'word) :to-equal "Baz")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal 77)
                          (expect (thing-at-point 'word) :to-equal "3")))
                    (it "returns ID's point when point is between subtitles."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (search-forward "Bar.\n")
                          (expect (thing-at-point 'line) :to-equal "\n")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal 39)
                          (expect (thing-at-point 'word) :to-equal "2")))
                    (it "returns nil if buffer is empty."
                        (with-temp-buffer
                          (expect (buffer-string) :to-equal "")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal nil)))
                    (it "returns ID's point when buffer starts with blank lines."
                        (with-temp-buffer
                          (insert (concat " \n \t \n" mock-srt-data))
                          (search-backward "Foo.")
                          (expect (thing-at-point 'line) :to-equal "Foo.\n")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal 7)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    (it "returns ID's point when subtitles are separated with blank lines."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (search-forward "Foo.\n")
                          (insert " \n \t \n")
                          (expect (subed-srt-move-to-subtitle-id) :to-equal 1)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    )
          (describe "to specific subtitle ID"
                    (it "returns ID's point if wanted ID exists."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-max))
                          (expect (subed-srt-move-to-subtitle-id 2) :to-equal 39)
                          (expect (thing-at-point 'word) :to-equal "2")
                          (expect (subed-srt-move-to-subtitle-id 1) :to-equal 1)
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-move-to-subtitle-id 3) :to-equal 77)
                          (expect (thing-at-point 'word) :to-equal "3")))
                    (it "returns nil and does not move if wanted ID does not exists."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (search-forward "Foo")
                          (let ((stored-point (point)))
                            (expect (subed-srt-move-to-subtitle-id 4) :to-equal nil)
                            (expect stored-point :to-equal (point)))))
                    )
          (describe "to subtitle ID at specific time"
                    (it "returns ID's point if point changed."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-max))
                          (spy-on 'subed-srt--subtitle-id-at-msecs :and-return-value (point-min))
                          (expect (subed-srt-move-to-subtitle-id-at-msecs 123456) :to-equal (point-min))
                          (expect (point) :to-equal (point-min))
                          (expect 'subed-srt--subtitle-id-at-msecs :to-have-been-called-with 123456)
                          (expect 'subed-srt--subtitle-id-at-msecs :to-have-been-called-times 1)))
                    (it "returns nil if point didn't change."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char 75)
                          (spy-on 'subed-srt--subtitle-id-at-msecs :and-return-value 75)
                          (expect (subed-srt-move-to-subtitle-id-at-msecs 123456) :to-equal nil)
                          (expect (point) :to-equal 75)
                          (expect 'subed-srt--subtitle-id-at-msecs :to-have-been-called-with 123456)
                          (expect 'subed-srt--subtitle-id-at-msecs :to-have-been-called-times 1)))
                    )
          (describe "to subtitle start time"
                    (it "returns start time's point if movement was successful."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (subed-srt-move-to-subtitle-time-start) :to-equal 3)
                          (expect (buffer-substring (point) (+ (point) subed-srt--length-timestamp)) :to-equal "00:01:01,000")
                          (re-search-forward "\n\n")
                          (expect (subed-srt-move-to-subtitle-time-start) :to-equal 41)
                          (expect (buffer-substring (point) (+ (point) subed-srt--length-timestamp)) :to-equal "00:02:02,234")
                          (re-search-forward "\n\n")
                          (expect (subed-srt-move-to-subtitle-time-start) :to-equal 79)
                          (expect (buffer-substring (point) (+ (point) subed-srt--length-timestamp)) :to-equal "00:03:03,456")))
                    (it "returns nil if movement failed."
                        (with-temp-buffer
                          (expect (subed-srt-move-to-subtitle-time-start) :to-equal nil)))
                    )
          (describe "to subtitle stop time"
                    (it "returns stop time's point if movement was successful."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (subed-srt-move-to-subtitle-time-stop) :to-equal 20)
                          (expect (buffer-substring (point) (+ (point) subed-srt--length-timestamp)) :to-equal "00:01:05,123")
                          (re-search-forward "\n\n")
                          (expect (subed-srt-move-to-subtitle-time-stop) :to-equal 58)
                          (expect (buffer-substring (point) (+ (point) subed-srt--length-timestamp)) :to-equal "00:02:10,345")
                          (re-search-forward "\n\n")
                          (expect (subed-srt-move-to-subtitle-time-stop) :to-equal 96)
                          (expect (buffer-substring (point) (+ (point) subed-srt--length-timestamp)) :to-equal "00:03:15,567")))
                    (it "returns nil if movement failed."
                        (with-temp-buffer
                          (expect (subed-srt-move-to-subtitle-time-stop) :to-equal nil)))
                    )
          (describe "to subtitle text"
                    (it "returns subtitle text's point if movement was successful."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (subed-srt-move-to-subtitle-text) :to-equal 33)
                          (expect (point) :to-equal (save-excursion (goto-char (point-max)) (search-backward "Foo.")))
                          (re-search-forward "\n\n")
                          (expect (subed-srt-move-to-subtitle-text) :to-equal 71)
                          (expect (point) :to-equal (save-excursion (goto-char (point-max)) (search-backward "Bar.")))
                          (re-search-forward "\n\n")
                          (expect (subed-srt-move-to-subtitle-text) :to-equal 109)
                          (expect (point) :to-equal (save-excursion (goto-char (point-max)) (search-backward "Baz.")))))
                    (it "returns nil if movement failed."
                        (with-temp-buffer
                          (expect (subed-srt-move-to-subtitle-time-stop) :to-equal nil)))
                    )
          (describe "to end of subtitle text"
                    (it "returns point if movement was successful."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (subed-srt-move-to-subtitle-end) :to-be 37)
                          (expect (looking-back "^Foo.$") :to-be t)
                          (forward-char 2)
                          (expect (subed-srt-move-to-subtitle-end) :to-be 75)
                          (expect (looking-back "^Bar.$") :to-be t)
                          (forward-char 2)
                          (expect (subed-srt-move-to-subtitle-end) :to-be 113)
                          (expect (looking-back "^Baz.$") :to-be t)
                          (goto-char (point-max))
                          (backward-char 2)
                          (expect (subed-srt-move-to-subtitle-end) :to-be 113)
                          (expect (looking-back "^Baz.$") :to-be t)))
                    (it "returns point if subtitle text is empty with trailing newline."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 1)
                          (kill-line)
                          (expect (subed-srt-move-to-subtitle-end) :to-be nil)
                          (expect (looking-at "^$") :to-be t)
                          (subed-srt-move-to-subtitle-text 2)
                          (kill-line)
                          (expect (subed-srt-move-to-subtitle-end) :to-be nil)
                          (expect (looking-at "^$") :to-be t)
                          (subed-srt-move-to-subtitle-text 3)
                          (kill-line)
                          (expect (subed-srt-move-to-subtitle-end) :to-be nil)
                          (expect (looking-at "^$") :to-be t)))
                    (it "returns point if subtitle text is empty without trailing newline."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 1)
                          (kill-whole-line)
                          (expect (subed-srt-move-to-subtitle-end) :to-be nil)
                          (expect (looking-at "^$") :to-be t)
                          (goto-char (point-min))
                          (expect (subed-srt-move-to-subtitle-end) :to-be 33)
                          (expect (looking-at "^$") :to-be t)))
                    (it "returns nil if movement failed."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-max))
                          (expect (subed-srt-move-to-subtitle-end) :to-be 113)
                          (expect (looking-back "^Baz.$") :to-be t)
                          (expect (subed-srt-move-to-subtitle-end) :to-be nil)
                          (expect (looking-back "^Baz.$") :to-be t)))
                    )
          (describe "to next subtitle ID"
                    (it "returns point when there is a next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 2)
                          (expect (thing-at-point 'word) :to-equal "2")
                          (expect (subed-srt-forward-subtitle-id) :to-be 77)
                          (expect (thing-at-point 'word) :to-equal "3")))
                    (it "returns nil and doesn't move when there is no next subtitle."
                        (with-temp-buffer
                          (insert (concat mock-srt-data "\n\n"))
                          (subed-srt-move-to-subtitle-text 3)
                          (expect (thing-at-point 'word) :to-equal "Baz")
                          (expect (subed-srt-forward-subtitle-id) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "Baz")))
                    )
          (describe "to previous subtitle ID"
                    (it "returns point when there is a previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 2)
                          (expect (thing-at-point 'word) :to-equal "2")
                          (expect (subed-srt-backward-subtitle-id) :to-be 1)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    (it "returns nil and doesn't move when there is no previous subtitle."
                        (with-temp-buffer
                          (goto-char (point-min))
                          (insert (concat mock-srt-data "\n\n"))
                          (subed-srt-move-to-subtitle-id 1)
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-backward-subtitle-id) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    )
          (describe "to next subtitle text"
                    (it "returns point when there is a next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 1)
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-forward-subtitle-text) :to-be 71)
                          (expect (thing-at-point 'word) :to-equal "Bar")))
                    (it "returns nil and doesn't move when there is no next subtitle."
                        (with-temp-buffer
                          (goto-char (point-max))
                          (insert (concat mock-srt-data "\n\n"))
                          (subed-srt-move-to-subtitle-id 3)
                          (expect (thing-at-point 'word) :to-equal "3")
                          (expect (subed-srt-forward-subtitle-text) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "3")))
                    )
          (describe "to previous subtitle text"
                    (it "returns point when there is a previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 3)
                          (expect (thing-at-point 'word) :to-equal "3")
                          (expect (subed-srt-backward-subtitle-text) :to-be 71)
                          (expect (thing-at-point 'word) :to-equal "Bar")))
                    (it "returns nil and doesn't move when there is no previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-backward-subtitle-text) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    )
          (describe "to next subtitle end"
                    (it "returns point when there is a next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 2)
                          (expect (thing-at-point 'word) :to-equal "Bar")
                          (expect (subed-srt-forward-subtitle-end) :to-be 113)
                          (expect (thing-at-point 'word) :to-equal nil)))
                    (it "returns nil and doesn't move when there is no next subtitle."
                        (with-temp-buffer
                          (insert (concat mock-srt-data "\n\n"))
                          (subed-srt-move-to-subtitle-text 3)
                          (end-of-line)
                          (expect (thing-at-point 'word) :to-equal nil)
                          (expect (subed-srt-forward-subtitle-end) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal nil)))
                    )
          (describe "to previous subtitle end"
                    (it "returns point when there is a previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 3)
                          (expect (thing-at-point 'word) :to-equal "3")
                          (expect (subed-srt-backward-subtitle-text) :to-be 71)
                          (expect (thing-at-point 'word) :to-equal "Bar")))
                    (it "returns nil and doesn't move when there is no previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-backward-subtitle-text) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    )
          (describe "to next subtitle start time"
                    (it "returns point when there is a next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 1)
                          (expect (thing-at-point 'word) :to-equal "Foo")
                          (expect (subed-srt-forward-subtitle-time-start) :to-be 41)
                          (expect (thing-at-point 'word) :to-equal "00")))
                    (it "returns nil and doesn't move when there is no next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 3)
                          (expect (thing-at-point 'word) :to-equal "3")
                          (expect (subed-srt-forward-subtitle-time-start) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "3")))
                    )
          (describe "to previous subtitle start time"
                    (it "returns point when there is a previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 2)
                          (expect (thing-at-point 'word) :to-equal "2")
                          (expect (subed-srt-backward-subtitle-time-start) :to-be 3)
                          (expect (thing-at-point 'word) :to-equal "00")))
                    (it "returns nil and doesn't move when there is no previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 1)
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-backward-subtitle-time-start) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    )
          (describe "to next subtitle stop time"
                    (it "returns point when there is a next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-text 1)
                          (expect (thing-at-point 'word) :to-equal "Foo")
                          (expect (subed-srt-forward-subtitle-time-stop) :to-be 58)
                          (expect (thing-at-point 'word) :to-equal "00")))
                    (it "returns nil and doesn't move when there is no next subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 3)
                          (expect (thing-at-point 'word) :to-equal "3")
                          (expect (subed-srt-forward-subtitle-time-stop) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "3")))
                    )
          (describe "to previous subtitle stop time"
                    (it "returns point when there is a previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 3)
                          (expect (thing-at-point 'word) :to-equal "3")
                          (expect (subed-srt-backward-subtitle-time-stop) :to-be 58)
                          (expect (thing-at-point 'word) :to-equal "00")))
                    (it "returns nil and doesn't move when there is no previous subtitle."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (subed-srt-move-to-subtitle-id 1)
                          (expect (thing-at-point 'word) :to-equal "1")
                          (expect (subed-srt-backward-subtitle-time-stop) :to-be nil)
                          (expect (thing-at-point 'word) :to-equal "1")))
                    )
          )

(describe "Adjusting subtitle start/stop time"
          :var (subed-subtitle-time-adjusted-hook)
          (it "runs the appropriate hook."
              (let ((foo (setf (symbol-function 'foo) (lambda (sub-id msecs) ()))))
                (spy-on 'foo)
                (add-hook 'subed-subtitle-time-adjusted-hook 'foo)
                (with-temp-buffer
                  (insert mock-srt-data)
                  (subed-srt-increase-start-time-100ms)
                  (expect 'foo :to-have-been-called-with 3 183556)
                  (expect 'foo :to-have-been-called-times 1)
                  (subed-srt-move-to-subtitle-id 1)
                  (subed-srt-increase-stop-time-100ms)
                  (expect 'foo :to-have-been-called-with 1 65223)
                  (expect 'foo :to-have-been-called-times 2)
                  (subed-srt-move-to-subtitle-end 2)
                  (subed-srt-decrease-start-time-100ms)
                  (expect 'foo :to-have-been-called-with 2 122134)
                  (expect 'foo :to-have-been-called-times 3)
                  (subed-srt-move-to-subtitle-text 3)
                  (subed-srt-decrease-stop-time-100ms)
                  (expect 'foo :to-have-been-called-with 3 195467)
                  (expect 'foo :to-have-been-called-times 4))))
          (it "adjusts the start/stop time."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-id 1)
                (subed-srt-increase-start-time-100ms)
                (expect (save-excursion (subed-srt-move-to-subtitle-time-start)
                                        (thing-at-point 'line)) :to-equal "00:01:01,100 --> 00:01:05,123\n")
                (subed-srt-decrease-start-time-100ms)
                (subed-srt-decrease-start-time-100ms)
                (expect (save-excursion (subed-srt-move-to-subtitle-time-start)
                                        (thing-at-point 'line)) :to-equal "00:01:00,900 --> 00:01:05,123\n")
                (subed-srt-increase-stop-time-100ms)
                (subed-srt-increase-stop-time-100ms)
                (expect (save-excursion (subed-srt-move-to-subtitle-time-start)
                                        (thing-at-point 'line)) :to-equal "00:01:00,900 --> 00:01:05,323\n")
                (subed-srt-decrease-stop-time-100ms)
                (expect (save-excursion (subed-srt-move-to-subtitle-time-start)
                                        (thing-at-point 'line)) :to-equal "00:01:00,900 --> 00:01:05,223\n")))
          )

(describe "Killing a subtitle"
          (it "removes it when it is the first one."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-text 1)
                (subed-srt-subtitle-kill)
                (expect (buffer-string) :to-equal (concat "2\n"
                                                          "00:02:02,234 --> 00:02:10,345\n"
                                                          "Bar.\n"
                                                          "\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          "Baz.\n"))))
          (it "removes it when it is in the middle."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-text 2)
                (subed-srt-subtitle-kill)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "Foo.\n"
                                                          "\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          "Baz.\n"))))
          (it "removes it when it is the last one."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-text 3)
                (subed-srt-subtitle-kill)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "Foo.\n"
                                                          "\n"
                                                          "2\n"
                                                          "00:02:02,234 --> 00:02:10,345\n"
                                                          "Bar.\n"))))
          (it "removes the previous subtitle when point is right above an ID."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-id 3)
                (backward-char)
                (expect (looking-at "^\n3\n") :to-be t)
                (subed-srt-subtitle-kill)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "Foo.\n"
                                                          "\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          "Baz.\n"))))
          )

(describe "Inserting"
          (describe "in an empty buffer,"
                    (describe "appending"
                              (it "a single subtile."
                                  (cl-loop for arg in (list nil 1) do
                                           (with-temp-buffer
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:00:00,100 --> 00:00:00,900\n\n"))
                                             (expect (point) :to-equal 33))))
                              (it "multiple subtiles."
                                  (cl-loop for arg in (list 2) do
                                           (with-temp-buffer
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:00:00,100 --> 00:00:00,950\n\n\n"
                                                                                       "2\n"
                                                                                       "00:00:01,050 --> 00:00:01,900\n\n"))
                                             (expect (point) :to-equal 33)))))
                    (describe "prepending"
                              (it "a single subtile."
                                  (cl-loop for arg in (list '- -1 (list 4)) do
                                           (with-temp-buffer
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:00:00,100 --> 00:00:00,900\n\n"))
                                             (expect (point) :to-equal 33))))
                              (it "multiple subtiles."
                                  (cl-loop for arg in (list -2 (list -16)) do
                                           (with-temp-buffer
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:00:00,100 --> 00:00:00,950\n\n\n"
                                                                                       "2\n"
                                                                                       "00:00:01,050 --> 00:00:01,900\n\n"))
                                             (expect (point) :to-equal 33)))))
                    )
          (describe "in a non-empty buffer"
                    (describe "before the current subtitle"
                              (it "a single subtitle."
                                  (cl-loop for arg in (list '- -1 (list 4)) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 2)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "2\n"
                                                                                       "00:01:05,223 --> 00:02:02,134\n"
                                                                                       "\n\n"
                                                                                       "3\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "4\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n"))
                                             (expect (point) :to-equal 71))))
                              (it "multiple subtitles."
                                  (cl-loop for arg in (list -2 (list 16)) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 2)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "2\n"
                                                                                       "00:01:05,223 --> 00:01:33,628\n"
                                                                                       "\n\n"
                                                                                       "3\n"
                                                                                       "00:01:33,728 --> 00:02:02,133\n"
                                                                                       "\n\n"
                                                                                       "4\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "5\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n"))
                                             (expect (point) :to-equal 71))))
                              )
                    (describe "after the current subtitle"
                              (it "a single subtitle."
                                  (cl-loop for arg in (list nil 1) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 1)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "2\n"
                                                                                       "00:01:05,223 --> 00:02:02,134\n"
                                                                                       "\n\n"
                                                                                       "3\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "4\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n"))
                                             (expect (point) :to-equal 71))))
                              (it "multiple subtitles."
                                  (cl-loop for arg in (list 2) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 1)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "2\n"
                                                                                       "00:01:05,223 --> 00:01:33,628\n"
                                                                                       "\n\n"
                                                                                       "3\n"
                                                                                       "00:01:33,728 --> 00:02:02,133\n"
                                                                                       "\n\n"
                                                                                       "4\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "5\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n"))
                                             (expect (point) :to-equal 71))))
                              )
                    (describe "before the first subtitle"
                              (it "a single subtitle."
                                  (cl-loop for arg in (list '- -1 (list 4)) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 1)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:00:00,100 --> 00:01:00,900\n"
                                                                                       "\n\n"
                                                                                       "2\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "3\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "4\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n"))
                                             (expect (point) :to-equal 33))))
                              (it "multiple subtitles."
                                  (cl-loop for arg in (list -2 (list 16)) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 1)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:00:00,100 --> 00:00:30,450\n"
                                                                                       "\n\n"
                                                                                       "2\n"
                                                                                       "00:00:30,550 --> 00:01:00,900\n"
                                                                                       "\n\n"
                                                                                       "3\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "4\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "5\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n"))
                                             (expect (point) :to-equal 33))))
                              )
                    (describe "after the last subtitle"
                              (it "a single subtitle."
                                  (cl-loop for arg in (list nil 1) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 3)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "2\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "3\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n\n"
                                                                                       "4\n"
                                                                                       "00:03:15,667 --> 00:03:16,467\n"
                                                                                       "\n"))
                                             (expect (point) :to-equal 147))))
                              (it "multiple subtitles."
                                  (cl-loop for arg in (list 2) do
                                           (with-temp-buffer
                                             (insert mock-srt-data)
                                             (subed-srt-move-to-subtitle-text 3)
                                             (subed-srt-subtitle-insert arg)
                                             (expect (buffer-string) :to-equal (concat "1\n"
                                                                                       "00:01:01,000 --> 00:01:05,123\n"
                                                                                       "Foo.\n\n"
                                                                                       "2\n"
                                                                                       "00:02:02,234 --> 00:02:10,345\n"
                                                                                       "Bar.\n\n"
                                                                                       "3\n"
                                                                                       "00:03:03,456 --> 00:03:15,567\n"
                                                                                       "Baz.\n\n"
                                                                                       "4\n"
                                                                                       "00:03:15,667 --> 00:03:16,517\n"
                                                                                       "\n\n"
                                                                                       "5\n"
                                                                                       "00:03:16,617 --> 00:03:17,467\n"
                                                                                       "\n"))
                                             (expect (point) :to-equal 147))))
                              )
                    )
          )

(describe "Sanitizing"
          (it "removes trailing tabs and spaces from all lines."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (while (re-search-forward "\n" nil t)
                  (replace-match " \n"))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data))
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (while (re-search-forward "\n" nil t)
                  (replace-match "\t\n"))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data)))
          (it "removes leading tabs and spaces from all lines."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (while (re-search-forward "\n" nil t)
                  (replace-match "\n "))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data))
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (while (re-search-forward "\n" nil t)
                  (replace-match "\n\t"))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data)))
          (it "removes excessive empty lines between subtitles."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (while (re-search-forward "\n\n" nil t)
                  (replace-match "\n \n  \t  \t\t  \n\n  \t\n"))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data)))
          (it "ensures double newline between subtitles if text of previous subtitle is empty."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-text 1)
                (kill-whole-line)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "\n"
                                                          "2\n"
                                                          "00:02:02,234 --> 00:02:10,345\n"
                                                          "Bar.\n\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          "Baz.\n"))
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "\n\n"
                                                          "2\n"
                                                          "00:02:02,234 --> 00:02:10,345\n"
                                                          "Bar.\n\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          "Baz.\n"))))
          (it "removes empty lines from beginning of buffer."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (insert " \n\t\n")
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data)))
          (it "removes empty lines from end of buffer."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-max))
                (insert " \n\t\n\n")
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data)))
          (it "ensures a single newline after the last subtitle."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-max))
                (while (eq (char-before (point-max)) ?\n)
                  (delete-backward-char 1))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal mock-srt-data)))
          (it "ensures single newline after last subtitle if text is empty."
              (with-temp-buffer
                (insert mock-srt-data)
                (subed-srt-move-to-subtitle-text 3)
                (kill-whole-line)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "Foo.\n\n"
                                                          "2\n"
                                                          "00:02:02,234 --> 00:02:10,345\n"
                                                          "Bar.\n\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          ""))
                (subed-srt-sanitize)
                (expect (buffer-string) :to-equal (concat "1\n"
                                                          "00:01:01,000 --> 00:01:05,123\n"
                                                          "Foo.\n\n"
                                                          "2\n"
                                                          "00:02:02,234 --> 00:02:10,345\n"
                                                          "Bar.\n\n"
                                                          "3\n"
                                                          "00:03:03,456 --> 00:03:15,567\n"
                                                          "\n"))))
          )

(describe "Renumbering"
          (it "ensures consecutive subtitle IDs."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (while (looking-at "^[0-9]$")
                  (replace-match "123"))
                (expect (buffer-string) :not :to-equal mock-srt-data)
                (subed-srt--regenerate-ids)
                (expect (buffer-string) :to-equal mock-srt-data))))

(describe "Sorting"
          (it "ensures subtitles are ordered by start time."
              (with-temp-buffer
                (insert mock-srt-data)
                (goto-char (point-min))
                (re-search-forward "01:01")
                (replace-match "12:01")
                (goto-char (point-min))
                (re-search-forward "02:02")
                (replace-match "10:02")
                (goto-char (point-min))
                (re-search-forward "03:03")
                (replace-match "11:03")
                (subed-srt-sort)
                (expect (buffer-string) :to-equal
                        (concat
                         "1\n"
                         "00:10:02,234 --> 00:02:10,345\n"
                         "Bar.\n"
                         "\n"
                         "2\n"
                         "00:11:03,456 --> 00:03:15,567\n"
                         "Baz.\n"
                         "\n"
                         "3\n"
                         "00:12:01,000 --> 00:01:05,123\n"
                         "Foo.\n"))))
          (describe "preserves point in the current subtitle"
                    (it "when subtitle text is non-empty."
                        (with-temp-buffer
                          (insert mock-srt-data)
                          (goto-char (point-min))
                          (re-search-forward "01:01")
                          (replace-match "12:01")
                          (search-forward "\n")
                          (expect (current-word) :to-equal "Foo")
                          (subed-srt-sort)
                          (expect (current-word) :to-equal "Foo")))
                    (it "when subtitle text is empty."
                        (with-temp-buffer
                          (insert "1\n00:12:01,000 --> 00:01:05,123\n")
                          (goto-char (point-max))
                          (subed-srt-sort)
                          (expect (point) :to-equal 33)))
                    )
          )
