class HomeController < ApplicationController
	require 'fedex'
	require 'json'
	
	def index

	end

	def importar
		begin
			file = params[:file]
			raise Exception.new('Error en importación: Debe elegir un archivo')	if file.blank?

			if String(File.extname(file.original_filename)).in?(%w(.json))
				fr = File.read(file)
				data_hash = JSON.parse(fr)
				packages = []
				data_hash.each do |d|
					procesar_etiquetas(d)
				end
			else			
				raise Exception.new("Error en importación: Formato de archivo desconocido #{file.original_filename}")
			end
		rescue Exception => e
			flash[:error] = e.message
			puts e.message.to_s
		end		
		redirect_to :action => :index
	end

	private

	def procesar_etiquetas(datos)	
		packages = []
		if datos["parcel"]["mass_unit"] == "KG" && datos["parcel"]["distance_unit"] == "CM"
			#Peso Total el mayor del peso en kilogramos y peso volumetrico
			peso_volumetrico = (datos["parcel"]["length"]*datos["parcel"]["width"]*datos["parcel"]["height"])/5000
			peso_kilogramo   = datos["parcel"]["weight"]
			peso_total = (peso_kilogramo > peso_volumetrico) ? peso_kilogramo : peso_volumetrico
			peso_indicado = peso_total.ceil
			#convertir cm a in 1cm -> 0.393701
			in_conv = 0.393701
			largo = (datos["parcel"]["length"] * in_conv).ceil 
			ancho = (datos["parcel"]["width"]  * in_conv).ceil
			alto  = (datos["parcel"]["height"] * in_conv).ceil
			#convertir kg a lb 1kg -> 2.20462
			lb_conv = 2.20462
			peso = (datos["parcel"]["weight"] * lb_conv).ceil

			packages << {
			  :weight => {:units => "LB", :value => peso },
			  :dimensions => {:length => largo, :width => ancho, :height => alto, :units => "IN" }
			}

			envios_fedex(packages) 
		elsif datos["parcel"]["mass_unit"] == "LB" && datos["parcel"]["distance_unit"] == "IN"
			#Aquí solo convertimos los datos del json a KG y CM
		end

		
	end

	def envios_fedex(paquete)

		shipper = { :name => "Sender",
            :company => "Company",
            :phone_number => "555-555-5555",
            :address => "Main Street",
            :city => "Harrison",
            :state => "AR",
            :postal_code => "72601",
            :country_code => "US" }

        recipient = { :name => "Recipient",
              :company => "Company",
              :phone_number => "555-555-5555",
              :address => "Main Street",
              :city => "Franklin Park",
              :state => "IL",
              :postal_code => "60131",
              :country_code => "US",
              :residential => "false" }

		shipping_options = {
  			:packaging_type => "YOUR_PACKAGING",
  			:drop_off_type => "REGULAR_PICKUP"
		}
		
		fedex = Fedex::Shipment.new(:key => 'O21wEWKhdDn2SYyb',
	                            :password => 'db0SYxXWWh0bgRSN7Ikg9Vunz',
	                            :account_number => '510087780',
	                            :meter => '119009727',
	                            :mode => 'test')

		rate = fedex.rate(:shipper=>shipper,
		                  :recipient => recipient,
		                  :packages => paquete,
		                  :service_type => "FEDEX_GROUND",
		                  :shipping_options => shipping_options)

		
		#retornar el peso de  lo que se ebvía a fedex
		puts rate[0].total_net_charge
		puts rate[0].total_billing_weigth

	end


end
