using Markdown
using InteractiveUtils
using CSV, CairoMakie, DataFrames, Dates

wind = CSV.read("wind-gen.csv", DataFrame)[!, 1:end-1]
sysdem = CSV.read("system-demand.csv", DataFrame)[!, 1:end-2]

days1 = length(wind.forecast)
date1 = Date(wind.period[1], "d U y H:M")
dayname(date1)

mondays = unique(
	map(wind.period) do elem
		elem = Date(elem, "d U y H:M")
	end
)[3:7:end] # 3rd elem is 2 days after day_name ie. first monday

mondayticks = ((96*3):(96*7):days1, string.(mondays))

fig1 = Figure()
ax1 = Axis(
	fig1[1,1], 
	xlabel="Day", 
	xticks=mondayticks,
	xticklabelrotation=45.0,
	ylabel="Wind (MW)", 
	title="Forecasted Wind vs Actual Wind"
)

windActualLines = lines!(
	ax1,
	collect(1:days1),
	map(wind.actual) do elem
		elem == "-" ? missing : parse(Int, elem)
	end,
	label="Actual"
)
windForecastLines = lines!(
	ax1,
	collect(1:days1),
	wind.forecast,
	label="Forecast"
)
axislegend(ax1)
fig1

days2 = length(sysdem.actual)
date2 = Date(sysdem.period[1], "d U y H:M")
dayname(date2)

mondays2 = unique(
	map(sysdem.period) do elem
		elem = Date(elem, "d U y H:M")
	end
)[1:7:end]

yticks = (3:4:24, string.(["2:00", "6:00", "10:00", "14:00", "18:00", "22:00"]))

fig2 = Figure()
ax2 = Axis(
	fig2[1,1],
	xlabel="Day", 
	xticks=(1:7, string.(mondays2)),
	xticklabelrotation=45.0,
	ylabel="Time", 
	yticks=yticks,
	title="Island-wide Electricity Demand over the Month"
)
sysdemParsed = map(sysdem.actual) do elem
		elem == "-" ? missing : parse(Int, elem)
end

sysdemHourly = []
for i in 1:4:days2
	elems = [sysdemParsed[x] for x in i:i+3]
	average = sum(skipmissing(elems), init=0)/4
	new_elem = trunc(Int64, average)
	push!(sysdemHourly, new_elem)
end

sysdemMatrix = reshape(
	sysdemHourly,
	24,
	:
)[:, 1:7:end]

sysdemHM = heatmap!(ax2, sysdemMatrix')
cb2 = Colorbar(fig2[1,2], sysdemHM)
for x in 1:7, y in 1:24
	num = sysdemMatrix'[x,y]
	text!(
		ax2,
		string.(num),
		position=(x,y),
		align=(:center, :center),
		color=ifelse.(num < 4000, :white, :black),
	)
end

fig2

save("wind-gen.png", fig1)
save("system-demand.png", fig2)
