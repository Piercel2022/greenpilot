require "prawn"
require "prawn/table"

module Pdf
  class InvoicePdf
    def initialize(invoice)
      @invoice = invoice
    end

    def render
      Prawn::Document.new(
        page_size: "A4",
        margin: [40, 45, 40, 45]
      ) do |pdf|
        build_header(pdf)
        build_invoice_information(pdf)
        build_customer_and_site(pdf)
        build_items(pdf)
        build_totals(pdf)
        build_payment(pdf)
        build_notes(pdf)
        build_footer(pdf)
      end.render
    end

    private

    def build_header(pdf)
      pdf.text "GREENPILOT", size: 22, style: :bold
      pdf.move_down 4

      pdf.fill_color "64748B"
      pdf.text "Facture", size: 11
      pdf.fill_color "000000"

      pdf.move_down 18
      pdf.stroke_horizontal_rule
      pdf.move_down 18
    end

    def build_invoice_information(pdf)
      pdf.text "FACTURE", size: 9, style: :bold, color: "059669"
      pdf.move_down 6

      pdf.text(
        @invoice.number,
        size: 18,
        style: :bold
      )

      pdf.move_down 10

      data = [
        [
          "Statut",
          invoice_status,
          "Date d'émission",
          format_date(@invoice.issue_date)
        ],
        [
          "Échéance",
          format_date(@invoice.due_date),
          "Paiement",
          payment_status
        ]
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [4, 6],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
        table.columns(2).font_style = :bold
      end

      pdf.move_down 20
    end

    def build_customer_and_site(pdf)
      customer = @invoice.customer
      site = @invoice.site
      job = @invoice.job
      quote = @invoice.quote

      pdf.text "CLIENT & INTERVENTION", size: 9, style: :bold, color: "059669"
      pdf.move_down 8

      data = [
        [
          "Client",
          customer_name(customer),
          "Site",
          site&.name.presence || "—"
        ],
        [
          "Email",
          customer&.try(:email).presence || "—",
          "Adresse",
          site_address(site)
        ],
        [
          "Intervention",
          job&.title.presence || "—",
          "Devis",
          quote_reference(quote)
        ]
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [4, 6],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
        table.columns(2).font_style = :bold
      end

      pdf.move_down 20
    end

    def build_items(pdf)
      pdf.text "DÉTAIL DE LA FACTURE", size: 9, style: :bold, color: "059669"
      pdf.move_down 8

      items = @invoice.invoice_items.order(:position)

      if items.empty?
        pdf.fill_color "F8FAFC"
        pdf.text(
          "Aucune ligne de facture.",
          size: 10,
          color: "334155"
        )
        pdf.fill_color "000000"
        pdf.move_down 18
        return
      end

      rows = [
        [
          "Description",
          "Unité",
          "Qté",
          "Prix unitaire",
          "Remise",
          "TVA",
          "Total HT"
        ]
      ]

      items.each do |item|
        rows << [
          item.description,
          item.unit,
          format_quantity(item.quantity),
          format_amount(item.unit_price),
          format_percentage(item.discount_percentage),
          format_percentage(item.tax_rate),
          format_amount(item.subtotal)
        ]
      end

      pdf.table(
        rows,
        width: pdf.bounds.width,
        header: true,
        cell_style: {
          borders: [],
          padding: [5, 5],
          size: 8
        }
      ) do |table|
        table.row(0).font_style = :bold
        table.row(0).text_color = "FFFFFF"
        table.row(0).background_color = "059669"

        table.columns(1..6).align = :right
        table.columns(2).align = :right
        table.columns(3).align = :right
        table.columns(4).align = :right
        table.columns(5).align = :right
        table.columns(6).align = :right
      end

      pdf.move_down 20
    end

    def build_totals(pdf)
      pdf.text "TOTALS", size: 9, style: :bold, color: "059669"
      pdf.move_down 8

      data = [
        ["Sous-total HT", format_amount(@invoice.subtotal)]
      ]

      if @invoice.discount_amount.to_f.positive?
        data << [
          "Remise",
          "-#{format_amount(@invoice.discount_amount)}"
        ]
      end

      data << [
        "TVA",
        format_amount(@invoice.tax_amount)
      ]

      data << [
        "Total TTC",
        format_amount(@invoice.total_amount)
      ]

      data << [
        "Montant payé",
        format_amount(@invoice.amount_paid)
      ]

      data << [
        "Reste à payer",
        format_amount(@invoice.amount_due)
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [5, 8],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
        table.columns(1).align = :right

        total_row = data.index { |row| row.first == "Total TTC" }

        if total_row
          table.row(total_row).font_style = :bold
          table.row(total_row).size = 11
        end

        due_row = data.index { |row| row.first == "Reste à payer" }

        if due_row
          table.row(due_row).font_style = :bold
        end
      end

      pdf.move_down 20
    end

    def build_payment(pdf)
      pdf.text "PAIEMENT", size: 9, style: :bold, color: "059669"
      pdf.move_down 8

      data = [
        [
          "Statut",
          payment_status,
          "Mode",
          @invoice.payment_method.presence || "—"
        ],
        [
          "Référence",
          @invoice.payment_reference.presence || "—",
          "Date de paiement",
          format_date(@invoice.paid_at)
        ]
      ]

      pdf.table(
        data,
        width: pdf.bounds.width,
        cell_style: {
          borders: [],
          padding: [4, 6],
          size: 9
        }
      ) do |table|
        table.columns(0).font_style = :bold
        table.columns(2).font_style = :bold
      end

      pdf.move_down 20
    end

    def build_notes(pdf)
      return unless @invoice.notes.present?

      pdf.text "NOTES", size: 9, style: :bold, color: "059669"
      pdf.move_down 6

      pdf.fill_color "F8FAFC"

      pdf.bounding_box(
        [0, pdf.cursor],
        width: pdf.bounds.width
      ) do
        pdf.text(
          @invoice.notes,
          size: 10,
          leading: 4,
          color: "334155"
        )
      end

      pdf.fill_color "000000"
    end

    def build_footer(pdf)
      pdf.number_pages(
        "Page <page> / <total>",
        at: [pdf.bounds.right - 100, 0],
        align: :right,
        size: 8,
        color: "64748B"
      )
    end

    def customer_name(customer)
      return "—" unless customer

      if customer.respond_to?(:name) && customer.name.present?
        customer.name
      elsif customer.respond_to?(:company_name) && customer.company_name.present?
        customer.company_name
      elsif customer.respond_to?(:first_name) ||
            customer.respond_to?(:last_name)
        [
          customer.try(:first_name),
          customer.try(:last_name)
        ].compact.join(" ").presence || "—"
      else
        "—"
      end
    end

    def site_address(site)
      return "—" unless site

      site.try(:address).presence || "—"
    end

    def quote_reference(quote)
      return "—" unless quote

      if quote.respond_to?(:number) && quote.number.present?
        quote.number
      elsif quote.respond_to?(:reference) && quote.reference.present?
        quote.reference
      else
        quote.id.to_s
      end
    end

    def invoice_status
      @invoice.status.presence || "—"
    end

    def payment_status
      return "Payée" if @invoice.amount_due.to_f <= 0
      return "Partiellement payée" if @invoice.amount_paid.to_f.positive?

      "À payer"
    end

    def format_date(value)
      return "—" unless value

      value.respond_to?(:strftime) ? value.strftime("%d/%m/%Y") : value.to_s
    end

    def format_amount(value)
      return "0,00 €" if value.nil?

      format("%.2f €", value.to_f).tr(".", ",")
    end

    def format_quantity(value)
      return "0" if value.nil?

      number = value.to_f

      if number == number.to_i
        number.to_i.to_s
      else
        format("%.2f", number).tr(".", ",")
      end
    end

    def format_percentage(value)
      return "0 %" if value.nil?

      number = value.to_f

      if number == number.to_i
        "#{number.to_i} %"
      else
        "#{format('%.2f', number).tr('.', ',')} %"
      end
    end
  end
end
