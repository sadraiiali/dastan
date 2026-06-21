/* SPDX-License-Identifier: AGPL-3.0-or-later */

#pragma once

#include <cairo.h>
#include <glib.h>

typedef struct _MarkViewerMathView MarkViewerMathView;

MarkViewerMathView *markviewer_math_view_ref (MarkViewerMathView *view);
MarkViewerMathView *markviewer_math_view_from_latex (const char *latex, GError **error);
void markviewer_math_view_unref (MarkViewerMathView *view);

void markviewer_math_view_set_resolution (MarkViewerMathView *view, double ppi);
void markviewer_math_view_set_foreground (MarkViewerMathView *view, const char *color);
void markviewer_math_view_set_math_size (MarkViewerMathView *view, double size_pt);
void markviewer_math_view_get_size_pixels (
    MarkViewerMathView *view,
    unsigned int *width,
    unsigned int *height,
    unsigned int *baseline
);
void markviewer_math_view_render (MarkViewerMathView *view, cairo_t *cr, double x, double y);