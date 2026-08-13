# import.R
# Format-specific readers for Q-sort data files. Every reader returns a
# qsort_data object in J x N orientation; read_qsort() dispatches to the
# right one by file extension and content (CSV, Excel, PQMethod .DAT, Ken-Q
# JSON / multi-sheet Excel, KADE ZIP, Easy-HTMLQ Firebase JSON).


#' Read Q-sort data from file
#'
#' @description
#' `read_qsort()` auto-detects the file format from extension and content
#' and dispatches to a specialised reader. The specialised readers are
#' also exported for explicit use:
#'
#' - `read_qsort_csv()`, `read_qsort_excel()` for generic CSV / Excel
#'   (with HTMLQ / FlashQ / Ken-Q auto-detection baked in)
#' - `read_pqmethod()` for PQMethod `.DAT` files
#' - `read_kenq()` for Ken-Q JSON or CSV
#' - `read_kenq_excel()` for multi-sheet Ken-Q Excel (Type 1 and Type 2,
#'   both old and Ver2 sub-formats)
#' - `read_kade_zip()` for KADE ZIP archives
#' - `read_easyhtml_firebase()` for Easy-HTMLQ Firebase JSON
#' - `read_statements()` for a standalone statement-text file
#'
#' All readers return a `qsort_data` object in `J x N` orientation
#' (statements as rows, participants as columns).
#'
#' @param file Path to the data file.
#' @param format For `read_qsort()`, `"auto"` (default) or one of
#'   `"csv"`, `"excel"`, `"pqmethod"`, `"kenq"`, `"kenq_excel"`,
#'   `"kade"`, `"easyhtml_firebase"`. For `read_kenq()`, one of
#'   `"auto"`, `"json"`, `"csv"`.
#' @param orientation For generic CSV/Excel: `"auto"`,
#'   `"statements_rows"`, or `"participants_rows"`.
#' @param id_col For generic CSV/Excel: `"auto"`, `"first"`, or `"none"`.
#' @param statements,distribution Optional overrides passed to
#'   [qsort_data()].
#' @param sheet Excel sheet name or index (default `1`).
#' @param statements_file For PQMethod, optional separate statements
#'   file.
#' @param column,id_column For `read_statements()`: column index or name.
#' @param ... Passed to the underlying reader.
#'
#' @return A `qsort_data` object, except `read_statements()` which
#'   returns a named character vector.
#'
#' @name read_qsort
#' @aliases read_qsort_csv read_qsort_excel read_pqmethod read_kenq read_kenq_excel read_kade_zip read_easyhtml_firebase read_statements
#' @export
read_qsort <- function(file, format = "auto", ...) {
  if (!file.exists(file)) stop("File not found: ", file)
  if (format == "auto") format <- detect_format(file)

  switch(format,
    csv      = read_qsort_csv(file, ...),
    excel    = read_qsort_excel(file, ...),
    pqmethod = read_pqmethod(file, ...),
    kenq     = read_kenq(file, ...),
    kenq_excel        = read_kenq_excel(file, ...),
    kade              = read_kade_zip(file, ...),
    easyhtml_firebase = read_easyhtml_firebase(file, ...),
    stop("Unknown format: ", format)
  )
}


#' @keywords internal
#' @noRd
detect_format <- function(file) {
  ext <- tolower(tools::file_ext(file))
  switch(ext,
    zip  = "kade",
    dat  = "pqmethod",
    json = detect_json_format(file),
    xlsx = ,
    xls  = "excel",
    csv  = ,
    tsv  = ,
    txt  = "csv",
    stop("No reader for extension: ", ext)
  )
}


#' @keywords internal
#' @noRd
detect_json_format <- function(file) {
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("Package 'jsonlite' is required for JSON input.")
  d <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  if (is.list(d) && "qSorts" %in% names(d))         return("kenq")
  if (is.list(d) && "respondentData" %in% names(d)) return("kenq")
  "easyhtml_firebase"
}


#' @rdname read_qsort
#' @export
read_qsort_csv <- function(file,
                           orientation = c("auto", "statements_rows", "participants_rows"),
                           id_col      = c("auto", "first", "none"),
                           statements = NULL, distribution = NULL, ...) {
  orientation <- match.arg(orientation)
  id_col      <- match.arg(id_col)
  raw <- utils::read.csv(file, stringsAsFactors = FALSE,
                         check.names = FALSE, ...)

  # HTMLQ and FlashQ are CSVs with distinctive headers; hand them off rather
  # than try to coerce the row/column structure.
  hdr <- tolower(names(raw))
  if (any(grepl("^uid$", hdr)) && any(grepl("datetime|timestamp", hdr)))
    return(parse_htmlq_frame(raw, variant = "htmlq",
                             source = paste0("htmlq:", basename(file))))
  if (any(grepl("^id$", hdr)) && any(grepl("^time$", hdr)))
    return(parse_htmlq_frame(raw, variant = "flashq",
                             source = paste0("flashq:", basename(file))))

  Y <- build_Y_from_frame(raw, orientation, id_col)
  qsort_data(Y, statements = statements, distribution = distribution,
             source = paste0("csv:", basename(file)))
}


#' @rdname read_qsort
#' @export
read_qsort_excel <- function(file, sheet = 1,
                             orientation = c("auto", "statements_rows", "participants_rows"),
                             id_col      = c("auto", "first", "none"),
                             statements = NULL, distribution = NULL, ...) {
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("Package 'readxl' is required for Excel input.")
  orientation <- match.arg(orientation)
  id_col      <- match.arg(id_col)

  # Multi-sheet Ken-Q workbooks have sheets named "sorts", "statements",
  # "pattern", etc. Detect and hand off to the dedicated Ken-Q reader.
  sheets <- tolower(readxl::excel_sheets(file))
  if (any(sheets %in% c("sorts", "qsorts", "q-sorts", "q sorts")) &&
      length(sheets) >= 2)
    return(read_kenq_excel(file))

  raw <- as.data.frame(readxl::read_excel(file, sheet = sheet, ...),
                       stringsAsFactors = FALSE)

  # HTMLQ / FlashQ / Q-Sortware tablet exports are also shipped as .xlsx.
  # Their header signatures are the same as the CSV variants.
  hdr <- tolower(names(raw))
  if (any(grepl("^uid$", hdr)) && any(grepl("datetime|timestamp", hdr)))
    return(parse_htmlq_frame(raw, variant = "htmlq",
                             source = paste0("htmlq:", basename(file))))
  if (any(grepl("^id$", hdr)) && any(grepl("^time$", hdr)))
    return(parse_htmlq_frame(raw, variant = "flashq",
                             source = paste0("flashq:", basename(file))))

  Y <- build_Y_from_frame(raw, orientation, id_col)
  qsort_data(Y, statements = statements, distribution = distribution,
             source = paste0("excel:", basename(file)))
}


# Collapse a wide data frame down to a J x N numeric matrix with statements
# as rows. Three cases are handled:
#   (a) columns named qsort1..qsortN or p1..pN: those columns are
#       participants; any remaining column becomes the statement IDs.
#   (b) first column non-numeric: treated as an ID column; orientation
#       from the user's argument or the shape heuristic.
#   (c) all-numeric grid: orientation from the argument; the default
#       puts the longer dimension in the rows.
#' @keywords internal
#' @noRd
build_Y_from_frame <- function(df, orientation, id_col) {
  if (ncol(df) < 2) stop("Data has fewer than 2 columns.")

  nm <- tolower(names(df))
  qcols <- grep("^q(sort)?\\d+$", nm)
  pcols <- grep("^p\\d+$",        nm)
  use_cols <- if (length(qcols) >= 2) qcols
              else if (length(pcols) >= 2) pcols
              else integer(0)

  if (length(use_cols) > 0) {
    other <- setdiff(seq_len(ncol(df)), use_cols)
    ids <- if (length(other) >= 1) as.character(df[[other[1]]]) else NULL
    val <- df[, use_cols, drop = FALSE]
    mat <- suppressWarnings(as.matrix(sapply(val, as.numeric)))
    if (!is.null(ids)) rownames(mat) <- ids
    colnames(mat) <- names(df)[use_cols]
    return(mat)
  }

  first <- df[[1]]
  first_is_id <- switch(id_col,
    "first" = TRUE,
    "none"  = FALSE,
    "auto"  = is.character(first) || is.factor(first))
  if (first_is_id) {
    ids <- as.character(first)
    val <- df[, -1, drop = FALSE]
  } else {
    ids <- NULL
    val <- df
  }

  mat <- suppressWarnings(as.matrix(sapply(val, as.numeric)))
  if (!is.null(ids))   rownames(mat) <- ids
  colnames(mat) <- names(val)

  if (orientation == "auto")
    orientation <- if (nrow(mat) >= ncol(mat)) "participants_rows"
                   else                         "statements_rows"
  if (orientation == "participants_rows") mat <- t(mat)
  mat
}


# PQMethod .DAT files come in two header flavours. Simple (A): line 1 is a
# title, line 2 has n_statements / min / max. Extended (B): line 1 starts
# with numbers, line 2 has min / max followed by the distribution counts.
#' @rdname read_qsort
#' @export
read_pqmethod <- function(file, statements_file = NULL) {
  lines <- readLines(file, warn = FALSE)
  if (length(lines) < 3) stop("PQMethod file too short: ", file)

  line1 <- lines[1]
  l2_nums <- suppressWarnings(as.numeric(regmatches(lines[2],
    gregexpr("-?\\d+", lines[2]))[[1]]))
  if (length(l2_nums) < 3) stop("Invalid PQMethod header.")

  is_ext <- grepl("^\\s*\\d+\\s+\\d+\\s+", line1) && length(l2_nums) > 3

  if (is_ext) {
    title   <- trimws(sub("^\\s*[\\d\\s]+", "", line1, perl = TRUE))
    min_val <- l2_nums[1]
    max_val <- l2_nums[2]
    counts  <- l2_nums[-(1:2)]
    n_stmts <- as.integer(sum(counts))
  } else {
    title   <- trimws(line1)
    n_stmts <- l2_nums[1]
    min_val <- l2_nums[2]
    max_val <- l2_nums[3]
    counts  <- NULL
  }
  if (!is.finite(n_stmts) || n_stmts <= 0 || n_stmts > 500)
    stop("Bad PQMethod n_statements: ", n_stmts)

  # Data rows use fixed-width encoding: ID field followed by 2-character
  # chunks per sort value (negatives fit without a separator, e.g. " 5-1").
  # ID width = total line width minus 2 * n_statements.
  data_lines <- lines[-(1:2)]
  data_lines <- data_lines[nchar(trimws(data_lines)) > 0]
  id_width <- nchar(data_lines[1]) - 2L * n_stmts
  if (id_width < 2 || id_width > 40) id_width <- 10L

  sorts <- matrix(NA_real_, nrow = length(data_lines), ncol = n_stmts)
  ids   <- character(length(data_lines))
  for (r in seq_along(data_lines)) {
    ln <- data_lines[r]
    if (nchar(ln) >= id_width + 2L * n_stmts) {
      ids[r] <- trimws(substr(ln, 1, id_width))
      vstr   <- substr(ln, id_width + 1, id_width + 2L * n_stmts)
      for (j in seq_len(n_stmts))
        sorts[r, j] <- suppressWarnings(as.numeric(
          trimws(substr(vstr, (j - 1) * 2 + 1, j * 2))))
    } else {
      parts <- strsplit(trimws(ln), "\\s+")[[1]]
      ids[r] <- parts[1]
      v <- suppressWarnings(as.numeric(parts[-1]))[seq_len(n_stmts)]
      sorts[r, ] <- v
    }
  }
  rownames(sorts) <- ids
  colnames(sorts) <- paste0("S", seq_len(n_stmts))

  stmt_texts <- NULL
  if (!is.null(statements_file) && file.exists(statements_file))
    stmt_texts <- read_pqmethod_statements(statements_file)

  distribution <- if (!is.null(counts)) counts
                  else as.integer(tabulate(match(sorts[1, ],
                    seq(min_val, max_val)), nbins = max_val - min_val + 1L))

  qsort_data(Y = t(sorts),
             statements   = stmt_texts %||% colnames(sorts),
             participants = rownames(sorts),
             distribution = distribution,
             metadata = list(title = title, pqmethod_range = c(min_val, max_val)),
             source = paste0("pqmethod:", basename(file)))
}


#' @keywords internal
#' @noRd
read_pqmethod_statements <- function(file) {
  lines <- readLines(file, warn = FALSE)
  lines <- lines[nchar(trimws(lines)) > 0]
  trimws(sub("^\\s*\\d+[.):;\\s]+", "", lines))
}


#' @keywords internal
#' @noRd
parse_htmlq_frame <- function(df, variant = "htmlq", source = NULL) {
  col_names <- names(df)

  # Explicit statement columns first (s1, s2, ... or statement_1, ...); fall
  # back to any numeric column that isn't clearly an ID or timestamp.
  stmt_cols <- grep("^s\\d+$|^statement[_-]?\\d+$",
                    col_names, ignore.case = TRUE)
  if (length(stmt_cols) == 0) {
    num_cols <- which(vapply(df, is.numeric, logical(1)))
    drop_ids <- tolower(col_names[num_cols]) %in%
      c("uid", "id", "record_id", "time", "duration")
    stmt_cols <- num_cols[!drop_ids]
  }
  if (length(stmt_cols) == 0)
    stop("Could not identify statement columns in HTMLQ data.")

  sorts <- suppressWarnings(as.matrix(sapply(df[, stmt_cols, drop = FALSE],
                                             as.numeric)))
  colnames(sorts) <- col_names[stmt_cols]

  id_col <- grep("^uid$|^id$|^participant", col_names, ignore.case = TRUE)
  ids <- if (length(id_col) > 0) as.character(df[[id_col[1]]])
         else paste0("P", seq_len(nrow(sorts)))
  rownames(sorts) <- ids

  meta_cols <- setdiff(seq_along(col_names), c(stmt_cols, id_col))
  metadata <- if (length(meta_cols) > 0)
                as.list(df[, meta_cols, drop = FALSE]) else list()

  qsort_data(Y = t(sorts),
             statements   = colnames(sorts),
             participants = rownames(sorts),
             metadata = metadata,
             source = source %||% paste0(variant, ":<frame>"))
}


#' @rdname read_qsort
#' @export
read_kenq <- function(file, format = c("auto", "json", "csv")) {
  format <- match.arg(format)
  if (format == "auto")
    format <- if (tolower(tools::file_ext(file)) == "json") "json" else "csv"
  if (format == "json") parse_kenq_json(file) else parse_kenq_csv(file)
}


#' @keywords internal
#' @noRd
parse_kenq_json <- function(file) {
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("Package 'jsonlite' is required for JSON input.")
  d <- jsonlite::fromJSON(file)

  if ("qSorts" %in% names(d)) {
    sorts <- if (is.matrix(d$qSorts)) d$qSorts else do.call(rbind, d$qSorts)
  } else if ("respondentData" %in% names(d)) {
    rd <- d$respondentData
    sorts <- if (is.data.frame(rd)) do.call(rbind, rd$sort)
             else do.call(rbind, lapply(rd, function(x) x$sort))
  } else {
    fb <- try_firebase_json(d)
    if (!is.null(fb)) return(fb)
    stop("Unrecognized Ken-Q / Easy-HTMLQ JSON structure.")
  }

  participants <- if ("participantNames" %in% names(d)) d$participantNames
                  else if (is.data.frame(d$respondentData))
                    d$respondentData$name %||% d$respondentData$id
                  else paste0("P", seq_len(nrow(sorts)))
  rownames(sorts) <- as.character(participants)

  stmts <- d$statementText %||% d$statements %||%
             paste0("S", seq_len(ncol(sorts)))
  colnames(sorts) <- if (length(stmts) == ncol(sorts)) stmts
                     else paste0("S", seq_len(ncol(sorts)))

  distribution <- d$sortPattern %||% d$distribution

  qsort_data(Y = t(sorts),
             statements = colnames(sorts),
             participants = rownames(sorts),
             distribution = distribution,
             metadata = list(kenq_version = d$version %||% "unknown"),
             source = paste0("kenq:", basename(file)))
}


#' @keywords internal
#' @noRd
parse_kenq_csv <- function(file) {
  df <- utils::read.csv(file, stringsAsFactors = FALSE, check.names = FALSE)
  parse_htmlq_frame(df, variant = "kenq",
                    source = paste0("kenq:", basename(file)))
}


# Easy-HTMLQ Firebase JSON: top-level keys are push IDs, each entry has a
# "sort" field holding pipe-delimited ranks.
#' @keywords internal
#' @noRd
try_firebase_json <- function(d) {
  if (is.data.frame(d) || !is.list(d)) return(NULL)
  has_sort <- vapply(d, function(x) is.list(x) && "sort" %in% names(x),
                     logical(1))
  if (!any(has_sort)) return(NULL)

  entries <- d[has_sort]
  rows <- list()
  names_out <- character()
  for (i in seq_along(entries)) {
    e <- entries[[i]]
    s <- gsub("\\+", "", as.character(e$sort))
    v <- suppressWarnings(as.numeric(strsplit(s, "\\|")[[1]]))
    if (length(v) == 0 || all(is.na(v))) next
    rows[[length(rows) + 1]] <- v
    key <- names(entries)[i]
    name <- e$name %||% e$email %||%
              substr(key, max(1, nchar(key) - 9), nchar(key))
    names_out <- c(names_out, as.character(name))
  }
  if (length(rows) == 0) return(NULL)

  sorts <- do.call(rbind, rows)
  rownames(sorts) <- names_out
  colnames(sorts) <- paste0("S", seq_len(ncol(sorts)))

  qsort_data(Y = t(sorts),
             statements = colnames(sorts),
             participants = rownames(sorts),
             metadata = list(format = "easyhtml_firebase"),
             source = "easyhtml:<json>")
}


#' @rdname read_qsort
#' @export
read_kenq_excel <- function(file) {
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("Package 'readxl' is required for Excel input.")
  sheets <- readxl::excel_sheets(file)
  sheets_lower <- tolower(sheets)

  # Ken-Q templates ship empty primary sheets with populated "Example - "
  # sheets alongside; prefer the populated one.
  find_sheet <- function(targets) {
    i <- which(sheets_lower %in% targets)[1]
    if (!is.na(i)) {
      test <- readxl::read_excel(file, sheet = sheets[i], col_names = FALSE)
      has_data <- nrow(test) > 1 &&
        any(!is.na(unlist(test[2:min(nrow(test), 5), ])))
      if (has_data) return(sheets[i])
    }
    ex <- which(sheets_lower %in% paste0("example - ", targets))[1]
    if (!is.na(ex)) return(sheets[ex])
    if (!is.na(i)) return(sheets[i])
    NULL
  }

  sorts_sheet <- find_sheet(c("sorts", "qsorts", "q-sorts", "q sorts"))
  if (is.null(sorts_sheet))
    stop("Not a valid Ken-Q Excel file: no 'sorts' sheet.")

  stmts <- NULL
  sh <- find_sheet(c("statements", "statement"))
  if (!is.null(sh)) stmts <- parse_kenq_statements_sheet(file, sh)

  distribution <- NULL
  sh <- find_sheet(c("pattern", "patterns"))
  if (!is.null(sh)) {
    mult <- parse_kenq_pattern_sheet(file, sh)
    if (!is.null(mult)) distribution <- multiplier_to_distribution(mult)
  }

  project_name <- "Ken-Q Project"
  ni <- which(sheets_lower %in% c("name", "names"))[1]
  if (!is.na(ni)) {
    nr <- readxl::read_excel(file, sheet = sheets[ni], col_names = FALSE)
    if (nrow(nr) >= 1) {
      idx <- if (nrow(nr) >= 2 && !is.na(nr[[1]][2])) 2L else 1L
      project_name <- as.character(nr[[1]][idx])
    }
  }

  kenq_type <- NULL
  ti <- which(sheets_lower == "type")[1]
  if (!is.na(ti)) {
    tr <- readxl::read_excel(file, sheet = sheets[ti], col_names = FALSE)
    if (nrow(tr) >= 2) kenq_type <- suppressWarnings(as.integer(tr[[1]][2]))
  }

  raw <- as.data.frame(readxl::read_excel(file, sheet = sorts_sheet,
                                          col_names = FALSE),
                       stringsAsFactors = FALSE)
  if (nrow(raw) < 2) stop("Ken-Q 'sorts' sheet is empty.")

  n_stmts <- if (!is.null(stmts)) length(stmts) else NULL
  parsed  <- detect_and_parse_kenq_sorts(raw, n_stmts, kenq_type)
  sorts   <- parsed$sorts

  qsort_data(
    Y            = t(sorts),
    statements   = stmts %||% colnames(sorts),
    participants = rownames(sorts),
    distribution = distribution %||% parsed$distribution,
    metadata     = list(project_name = project_name,
                        kenq_format = parsed$format_type),
    source       = paste0("kenq-excel:", basename(file))
  )
}


# Pick a parser based on the "type" sheet when present, otherwise fall back
# to structural heuristics: a "Sort Pattern" row signals Type 2 (old); a
# header row with names in cols B+ signals Type 1 Ver2; a long header block
# (22 rows) followed by names + numeric data signals Type 1 Ver1.
#' @keywords internal
#' @noRd
detect_and_parse_kenq_sorts <- function(raw, n_stmts, kenq_type) {
  if (isTRUE(kenq_type == 1L)) return(parse_kenq_type1_ver2(raw, n_stmts))
  if (isTRUE(kenq_type == 2L)) {
    sp_row <- find_sort_pattern_row(raw)
    if (!is.null(sp_row))
      return(parse_kenq_type2_old(raw, sort_pattern_row = sp_row))
    return(parse_kenq_type2_ver2(raw))
  }

  sp_row <- find_sort_pattern_row(raw)
  if (!is.null(sp_row))
    return(parse_kenq_type2_old(raw, sort_pattern_row = sp_row))

  first_cell <- trimws(as.character(raw[1, 1]))
  first_blank  <- is.na(first_cell) || nchar(first_cell) == 0
  first_header <- !is.na(first_cell) &&
    grepl("respondent|sort\\s*value|name", first_cell, ignore.case = TRUE)
  if ((first_blank || first_header) && ncol(raw) > 1) {
    second <- as.character(raw[1, 2])
    if (!is.na(second) && !grepl("^-?\\d+\\.?\\d*$", trimws(second)))
      return(parse_kenq_type1_ver2(raw, n_stmts))
  }

  if (nrow(raw) > 25) {
    row2col2 <- as.character(raw[2, 2])
    if (!is.na(row2col2) && !grepl("^-?\\d+$", trimws(row2col2)) &&
        nchar(trimws(row2col2)) > 2) {
      sv_rows_ok <- TRUE
      for (r in seq.int(3L, min(22L, nrow(raw)))) {
        v <- suppressWarnings(as.numeric(raw[r, 1]))
        blank <- is.na(raw[r, 1]) ||
          nchar(trimws(as.character(raw[r, 1]))) == 0
        if (!is.na(v) || blank) next
        sv_rows_ok <- FALSE; break
      }
      if (sv_rows_ok) return(parse_kenq_type1_ver1(raw, n_stmts))
    }
  }

  first_txt <- !is.na(as.character(raw[1, 1])) &&
    !grepl("^-?\\d+\\.?\\d*$", trimws(as.character(raw[1, 1])))
  if (first_txt && ncol(raw) > 2) {
    sample <- suppressWarnings(as.numeric(raw[1, 2:ncol(raw)]))
    if (sum(!is.na(sample)) > (ncol(raw) - 1) * 0.5)
      return(parse_kenq_type2_ver2(raw))
  }

  stop("Could not determine Ken-Q Excel format (Type 1 or Type 2).")
}


#' @keywords internal
#' @noRd
find_sort_pattern_row <- function(raw) {
  for (i in seq_len(min(5, nrow(raw))))
    for (j in seq_len(min(5, ncol(raw)))) {
      v <- as.character(raw[i, j])
      if (!is.na(v) && grepl("sort\\s*pattern", v, ignore.case = TRUE))
        return(i)
    }
  NULL
}


#' @keywords internal
#' @noRd
parse_kenq_type1_ver2 <- function(raw, n_stmts) {
  na_mask <- vapply(raw[1, ], is.na, logical(1))
  names_row <- as.character(raw[1, ])
  ids <- names_row[-1]
  ids <- ids[!na_mask[-1] & nchar(trimws(ids)) > 0 &
             !grepl("^-?\\d+\\.?\\d*$", trimws(ids))]
  n_part <- length(ids)

  rows <- raw[-1, , drop = FALSE]
  sv <- suppressWarnings(as.numeric(rows[[1]]))
  ok <- !is.na(sv); sv <- sv[ok]
  stmt_data <- rows[ok, 2:(n_part + 1), drop = FALSE]

  if (is.null(n_stmts)) {
    all_nums <- suppressWarnings(
      as.integer(round(as.numeric(unlist(stmt_data)))))
    n_stmts <- max(all_nums, na.rm = TRUE)
  }

  sorts <- type1_to_sorts_matrix(sv, stmt_data, n_part, n_stmts, ids)
  dist  <- as.integer(tabulate(match(sv, seq(min(sv), max(sv))),
                               nbins = max(sv) - min(sv) + 1L))
  list(sorts = sorts, distribution = dist, format_type = "type1_ver2")
}


#' @keywords internal
#' @noRd
parse_kenq_type1_ver1 <- function(raw, n_stmts) {
  names_row_idx <- NULL
  if (nrow(raw) < 20L)
    stop("Ken-Q Type 1 Ver1: sheet has fewer than 20 rows.")
  for (i in seq.int(20L, min(28L, nrow(raw)))) {
    v <- as.character(raw[i, 2])
    if (!is.na(v) && nchar(trimws(v)) > 0 &&
        !grepl("^-?\\d+\\.?\\d*$", trimws(v))) {
      names_row_idx <- i; break
    }
  }
  if (is.null(names_row_idx))
    stop("Ken-Q Type 1 Ver1: cannot locate participant-names row.")

  ids <- as.character(raw[names_row_idx, ])[-1]
  ids <- ids[!is.na(ids) & nchar(trimws(ids)) > 0]
  n_part <- length(ids)

  rows <- raw[(names_row_idx + 1):nrow(raw), , drop = FALSE]
  valid <- apply(rows, 1, function(r) !all(is.na(r) |
                   nchar(trimws(as.character(r))) == 0))
  rows <- rows[valid, , drop = FALSE]

  sv <- suppressWarnings(as.numeric(rows[[1]]))
  ok <- !is.na(sv); sv <- sv[ok]
  stmt_data <- rows[ok, 2:(n_part + 1), drop = FALSE]

  if (is.null(n_stmts)) {
    all_nums <- suppressWarnings(
      as.integer(round(as.numeric(unlist(stmt_data)))))
    n_stmts <- max(all_nums, na.rm = TRUE)
  }

  sorts <- type1_to_sorts_matrix(sv, stmt_data, n_part, n_stmts, ids)
  dist  <- as.integer(tabulate(match(sv, seq(min(sv), max(sv))),
                               nbins = max(sv) - min(sv) + 1L))
  list(sorts = sorts, distribution = dist, format_type = "type1_ver1")
}


#' @keywords internal
#' @noRd
parse_kenq_type2_old <- function(raw, sort_pattern_row) {
  cells <- as.character(raw[sort_pattern_row, ])
  pat <- suppressWarnings(as.numeric(cells))
  pat <- pat[!is.na(pat)]
  dist <- if (length(pat) > 0)
            as.integer(tabulate(match(pat, seq(min(pat), max(pat))),
                                nbins = max(pat) - min(pat) + 1L))
          else NULL

  i <- sort_pattern_row + 1L
  while (i <= nrow(raw)) {
    f <- trimws(as.character(raw[i, 1]))
    if (!is.na(f) && nchar(f) > 0 &&
        !grepl("^-?\\d+\\.?\\d*$", f) &&
        !grepl("sort\\s*pattern", f, ignore.case = TRUE)) break
    i <- i + 1L
  }
  if (i > nrow(raw))
    stop("Ken-Q Type 2: no participant rows after Sort Pattern.")

  rows <- raw[i:nrow(raw), , drop = FALSE]
  valid <- apply(rows, 1, function(r) {
    f <- trimws(as.character(r[1]))
    !is.na(f) && nchar(f) > 0
  })
  rows <- rows[valid, , drop = FALSE]

  ids <- as.character(rows[[1]])
  sorts <- suppressWarnings(
    apply(rows[, -1, drop = FALSE], 2, as.numeric))
  if (!is.matrix(sorts)) sorts <- as.matrix(sorts)
  sorts <- sorts[, !apply(sorts, 2, function(c) all(is.na(c))),
                 drop = FALSE]
  rownames(sorts) <- ids

  list(sorts = sorts, distribution = dist, format_type = "type2_old")
}


#' @keywords internal
#' @noRd
parse_kenq_type2_ver2 <- function(raw) {
  valid <- apply(raw, 1, function(r) {
    f <- trimws(as.character(r[1]))
    !is.na(f) && nchar(f) > 0
  })
  raw <- raw[valid, , drop = FALSE]

  ids <- as.character(raw[[1]])
  sorts <- suppressWarnings(
    apply(raw[, -1, drop = FALSE], 2, as.numeric))
  if (!is.matrix(sorts)) sorts <- as.matrix(sorts)
  sorts <- sorts[, !apply(sorts, 2, function(c) all(is.na(c))),
                 drop = FALSE]
  rownames(sorts) <- ids
  list(sorts = sorts, distribution = NULL, format_type = "type2_ver2")
}


# In the Type 1 layout, each data row has a sort value in column 1 and, in
# the remaining columns, the statement number each participant placed at
# that sort value. This inverts that layout back to the canonical
# participant-by-statement matrix.
#' @keywords internal
#' @noRd
type1_to_sorts_matrix <- function(sv, stmt_data, n_part, n_stmts, ids) {
  sorts <- matrix(NA_real_, n_part, n_stmts,
                  dimnames = list(ids, paste0("S", seq_len(n_stmts))))
  for (p in seq_len(n_part)) {
    sn <- suppressWarnings(as.integer(round(as.numeric(stmt_data[, p]))))
    for (r in seq_along(sv))
      if (!is.na(sn[r]) && sn[r] >= 1L && sn[r] <= n_stmts)
        sorts[p, sn[r]] <- sv[r]
  }
  sorts
}


#' @keywords internal
#' @noRd
parse_kenq_statements_sheet <- function(file, sheet_name) {
  df <- readxl::read_excel(file, sheet = sheet_name)
  col <- which(tolower(names(df)) == "statements")[1]
  if (is.na(col)) col <- 1
  s <- as.character(df[[col]])
  s <- s[!is.na(s) & nchar(trimws(s)) > 0]
  s <- s[!grepl("^\\s*\\.?\\s*$", s)]
  if (length(s) == 0) NULL else s
}


#' @keywords internal
#' @noRd
parse_kenq_pattern_sheet <- function(file, sheet_name) {
  df <- readxl::read_excel(file, sheet = sheet_name, col_names = FALSE)
  for (r in c(2, 1, 3)) {
    if (r > nrow(df)) next
    txt <- paste(as.character(df[r, ]), collapse = ",")
    v <- suppressWarnings(as.numeric(
      strsplit(gsub("[^0-9,.-]", "", txt), ",")[[1]]))
    v <- v[!is.na(v)]
    if (length(v) >= 5) {
      if (length(v) < 20) v <- c(v, rep(0, 20 - length(v)))
      return(v[1:20])
    }
  }
  NULL
}


#' @keywords internal
#' @noRd
multiplier_to_distribution <- function(mult) {
  if (is.null(mult)) return(NULL)
  mult <- as.numeric(mult)
  nz <- which(mult > 0)
  if (length(nz) == 0) return(NULL)
  as.integer(mult[min(nz):max(nz)])
}


# A KADE archive holds four text files: sorts.txt (name + scores per row),
# statements.txt (one per line), pattern.txt (20-slot multiplier array),
# and name.txt (project title). The delimiter is comma or semicolon.
#' @rdname read_qsort
#' @export
read_kade_zip <- function(file) {
  tmp <- tempfile("kade_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  ex <- utils::unzip(file, exdir = tmp)
  bn <- tolower(basename(ex))

  sorts_file   <- ex[grepl("^sorts",     bn)][1]
  name_file    <- ex[grepl("^name",      bn)][1]
  stmts_file   <- ex[grepl("^statement", bn)][1]
  pattern_file <- ex[grepl("^pattern",   bn)][1]
  if (is.na(sorts_file)) stop("Not a valid KADE ZIP: missing sorts.txt")

  project_name <- "KADE Project"
  if (!is.na(name_file)) {
    ln <- trimws(readLines(name_file, warn = FALSE))
    ln <- ln[nchar(ln) > 0]
    if (length(ln) > 0) project_name <- ln[1]
  }

  stmts <- NULL
  if (!is.na(stmts_file)) {
    ln <- trimws(readLines(stmts_file, warn = FALSE))
    stmts <- ln[nchar(ln) > 0]
  }

  distribution <- NULL
  if (!is.na(pattern_file)) {
    ln <- trimws(readLines(pattern_file, warn = FALSE))
    ln <- ln[nchar(ln) > 0][1]
    delim <- if (length(gregexpr(";", ln)[[1]]) >
                 length(gregexpr(",", ln)[[1]])) ";" else ","
    mult <- suppressWarnings(as.numeric(strsplit(ln, delim)[[1]]))
    mult <- mult[!is.na(mult)]
    if (length(mult) > 0) {
      if (length(mult) < 20) mult <- c(mult, rep(0, 20 - length(mult)))
      distribution <- multiplier_to_distribution(mult[1:20])
    }
  }

  sl <- readLines(sorts_file, warn = FALSE)
  sl <- sl[nchar(trimws(sl)) > 0]
  if (length(sl) == 0) stop("KADE sorts.txt is empty.")
  delim <- if (length(gregexpr(";", sl[1])[[1]]) >
               length(gregexpr(",", sl[1])[[1]])) ";" else ","

  ids <- character()
  rows <- list()
  for (ln in sl) {
    parts <- trimws(strsplit(ln, delim)[[1]])
    ids <- c(ids, parts[1])
    rows[[length(rows) + 1]] <- suppressWarnings(as.numeric(parts[-1]))
  }
  sorts <- do.call(rbind, rows)
  rownames(sorts) <- ids
  if (!is.null(stmts) && length(stmts) == ncol(sorts))
    colnames(sorts) <- stmts
  else
    colnames(sorts) <- paste0("S", seq_len(ncol(sorts)))

  qsort_data(Y = t(sorts),
             statements   = colnames(sorts),
             participants = rownames(sorts),
             distribution = distribution,
             metadata = list(project_name = project_name),
             source = paste0("kade:", basename(file)))
}


#' @rdname read_qsort
#' @export
read_easyhtml_firebase <- function(file) {
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("Package 'jsonlite' is required for JSON input.")
  d <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  r <- try_firebase_json(d)
  if (is.null(r)) stop("Not a recognizable Easy-HTMLQ Firebase JSON.")
  r$source <- paste0("easyhtml:", basename(file))
  r
}


#' @rdname read_qsort
#' @export
read_statements <- function(file, column = 1, id_column = NULL) {
  ext <- tolower(tools::file_ext(file))
  if (ext %in% c("csv", "tsv")) {
    df <- utils::read.csv(file, stringsAsFactors = FALSE,
                          check.names = FALSE)
  } else if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE))
      stop("Package 'readxl' is required for Excel input.")
    df <- as.data.frame(readxl::read_excel(file),
                        stringsAsFactors = FALSE)
  } else if (ext == "txt") {
    s <- trimws(readLines(file, warn = FALSE))
    s <- s[nchar(s) > 0]
    names(s) <- paste0("S", seq_along(s))
    return(s)
  } else {
    stop("Unsupported statements file: ", ext)
  }

  s <- as.character(df[[column]])
  names(s) <- if (!is.null(id_column)) as.character(df[[id_column]])
              else paste0("S", seq_along(s))
  s
}


#' @keywords internal
#' @noRd
`%||%` <- function(a, b) if (is.null(a)) b else a


# Dotted-name aliases for migration from the qmethod package, which uses
# import.pqmethod() / import.htmlq() / import.easyhtmlq(). Thin wrappers
# around the snake_case readers; scripts written against qmethod keep working.

#' qmethod-style import aliases
#'
#' @description
#' Thin aliases that forward to [read_pqmethod()], [read_qsort()] (HTMLQ
#' auto-detection), [read_kenq()], and [read_easyhtml_firebase()]. These
#' exist only so scripts written against the `qmethod` package continue
#' to work; new code should call the `read_*` functions directly.
#'
#' @param file Path to the data file.
#' @param ... Passed to the underlying reader.
#'
#' @return A `qsort_data` object.
#'
#' @name import-aliases
#' @aliases import.pqmethod import.htmlq import.kenq import.easyhtmlq
#' @export
import.pqmethod <- function(file, ...) read_pqmethod(file, ...)

#' @rdname import-aliases
#' @export
import.htmlq <- function(file, ...) read_qsort(file, format = "csv", ...)

#' @rdname import-aliases
#' @export
import.kenq <- function(file, ...) read_kenq(file, ...)

#' @rdname import-aliases
#' @export
import.easyhtmlq <- function(file, ...) read_easyhtml_firebase(file, ...)
