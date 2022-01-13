function normalized_v = ensure_normalized(v)
  len = norm(v, "cols");
  if (abs(len - 1) > 1e-12)
    warning(
      "Got a normal with length = 1 + %s: %s",
      mat2str(len - 1), mat2str(v));
  endif
  normalized_v = v ./ len;
endfunction
