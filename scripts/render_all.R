# Render every supported CV format from the same master.yml file.

profiles <- c("html", "word", "typst", "latex")

quarto_bin <- Sys.which("quarto")

if (!nzchar(quarto_bin)) {
  stop(
    "Quarto was not found. Install Quarto and ensure it is available on PATH.",
    call. = FALSE
  )
}

for (profile in profiles) {
  message("Rendering profile: ", profile)

  status <- system2(
    command = quarto_bin,
    args = c("render", "cv.qmd", "--profile", profile)
  )

  if (!identical(status, 0L)) {
    stop("Rendering failed for profile: ", profile, call. = FALSE)
  }
}

message("All CV formats rendered successfully.")

