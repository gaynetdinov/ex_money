defmodule ExMoney.Web.Settings.LoginView do
  use ExMoney.Web, :view

  def show_params(params) do
    inspect(params)
  end

  def disabled_previous_page?(page_number, total_pages) do
    if page_number == 1 or total_pages == 1 do
      "disabled"
    end
  end

  def disabled_next_page?(page_number, total_pages) do
    if (page_number + 1) >= total_pages do
      "disabled"
    end
  end

  def build_next_page_url(login_id, page_number, total_pages) do
    next_page = page_number + 1

    case next_page >= total_pages do
      true -> "#"
      false -> "#{login_id}?page=#{next_page}"
    end
  end

  def build_previous_page_url(login_id, page_number) do
    previous_page = page_number - 1

    case previous_page <= 0 do
      true -> "#"
      false -> "#{login_id}?page=#{previous_page}"
    end
  end
end
