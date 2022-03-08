

.SUPPORTED_LANGUAGES = readLines(file.path(getwd(), "data", "supported_lang.txt"), encoding = "UTF-8")

test_that("ascii code converter", {
  obj = str_to_ascii_code(.SUPPORTED_LANGUAGES)
  expect_equal(ascii_code_to_str(obj), .SUPPORTED_LANGUAGES)
})
