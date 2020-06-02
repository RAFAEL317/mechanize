defmodule Mechanize.Form.SelectList do
  @moduledoc false

  alias Mechanize.Page.{Element, Elementable}
  alias Mechanize.Form.{Option, InconsistentFormError}
  alias Mechanize.Query
  alias Mechanize.Query.BadCriteriaError
  alias Mechanize.{Form, Query, Queryable}

  use Mechanize.Form.FieldMatcher

  @derive [Queryable, Elementable]
  @enforce_keys [:element]
  defstruct element: nil, name: nil, options: []

  @type t :: %__MODULE__{
          element: Element.t(),
          name: String.t(),
          options: list()
        }

  def new(%Element{} = el) do
    %__MODULE__{
      element: el,
      name: Element.attr(el, :name),
      options: fetch_options(el)
    }
  end

  defdelegate fetch(term, key), to: Map
  defdelegate get_and_update(data, key, function), to: Map
  defdelegate pop(data, key), to: Map

  def options(%__MODULE__{} = select), do: options([select])
  def options(selects), do: Enum.flat_map(selects, & &1.options)

  def selected_options(selects) do
    selects
    |> options()
    |> Enum.filter(fn opt -> opt.selected end)
  end

  defp fetch_options(el) do
    el
    |> Query.search("option")
    |> Enum.with_index()
    |> Enum.map(&Option.new(&1))
  end

  defp assert_select_found(form, criteria) do
    selects = get_in(form, [:fields, Access.filter(&Query.match_criteria?(&1, criteria))])

    if selects == [] do
      raise(BadCriteriaError, "No select found with criteria #{inspect(criteria)}")
    end

    form
  end

  defp assert_options_found(form, criteria, opts_criteria) do
    options =
      get_in(form, [
        :fields,
        Access.filter(&Query.match_criteria?(&1, criteria)),
        :options,
        Access.filter(&Query.match_criteria?(&1, opts_criteria))
      ])

    if options == [[]] do
      raise(BadCriteriaError, "No option found with criteria #{inspect(criteria)} in select")
    end

    form
  end

  def select(form, criteria) do
    {opts_criteria, criteria} = Keyword.pop(criteria, :option, [])

    form
    |> assert_select_found(criteria)
    |> assert_options_found(criteria, opts_criteria)
    |> ensure_single_selected(criteria)
    |> update_select(criteria, opts_criteria, true)
    |> assert_single_option_selected()
  end

  defp ensure_single_selected(form, criteria) do
    put_in(
      form,
      [
        :fields,
        Access.filter(&match_single_selection?(&1, criteria)),
        :options,
        Access.all(),
        :selected
      ],
      false
    )
  end

  defp match_single_selection?(select, criteria) do
    !Element.attr_present?(select, :multiple) and Query.match_criteria?(select, criteria)
  end

  defp update_select(form, criteria, opts_criteria, selected) do
    put_in(
      form,
      [
        :fields,
        Access.filter(&Query.match_criteria?(&1, criteria)),
        :options,
        Access.filter(&Query.match_criteria?(&1, opts_criteria)),
        :selected
      ],
      selected
    )
  end

  def unselect(form, criteria) do
    {opts_criteria, criteria} = Keyword.pop(criteria, :option, [])

    form
    |> assert_select_found(criteria)
    |> assert_options_found(criteria, opts_criteria)
    |> update_select(criteria, opts_criteria, false)
  end

  defp assert_single_option_selected(form) do
    form
    |> Form.select_lists_with(multiple: false)
    |> Stream.map(fn select -> {select.name, length(selected_options(select))} end)
    |> Stream.filter(fn {_, selected} -> selected > 1 end)
    |> Enum.map(fn {name, _} -> name end)
    |> case do
      [] ->
        form

      names ->
        raise InconsistentFormError,
              "Multiple selected options on single select list with name(s) #{names}"
    end
  end
end

defimpl Mechanize.Form.ParameterizableField, for: Mechanize.Form.SelectList do
  alias Mechanize.Form.SelectList

  def to_param(select) do
    case SelectList.selected_options(select) do
      [] ->
        option =
          select
          |> SelectList.options()
          |> List.first()

        [{select.name, option.value}]

      options ->
        options
        |> Enum.map(&{select.name, &1.value})
    end
  end
end
