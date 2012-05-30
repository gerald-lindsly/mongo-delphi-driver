var
  i : integer;
begin
  SetLength(Result, length(Arr));
  for i := low(Arr) to high(Arr) do
    Result[i] := Arr[i];
end;