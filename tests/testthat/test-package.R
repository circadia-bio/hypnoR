test_that("hypnoR package loads", {
  expect_true(is.character(packageVersion("hypnoR") |> as.character()))
})
