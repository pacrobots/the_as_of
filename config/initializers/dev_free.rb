# frozen_string_literal: true

# DEV_FREE=1 skips charge (PRD §7). Deduction lands in S5; the flag is readable now.
ENV["DEV_FREE"] ||= "1" if Lightyear.env != "production"
