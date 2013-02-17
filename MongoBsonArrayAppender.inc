var
  i : Cardinal;
begin
  if FromIndex = 0 then
    begin
      FromIndex := length(TargetArray);
      SetLength(TargetArray, length(TargetArray) + length(Arr));
    end;
  for i := low(Arr) to high(Arr) do
    TargetArray[i + FromIndex] := Arr[i];
end;