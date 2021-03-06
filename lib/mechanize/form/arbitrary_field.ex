defmodule Mechanize.Form.ArbitraryField do
  @moduledoc false

  alias Mechanize.Form.ParameterizableField

  @derive [ParameterizableField]
  @enforce_keys [:name, :value]
  defstruct name: nil, value: nil

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t()
        }

  def new(name, value) do
    %Mechanize.Form.ArbitraryField{name: name, value: value}
  end
end
