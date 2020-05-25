class Api::V1::ClientRequestsController < Api::ApiV1Controller

  def compute_count
    params.permit!
    data = ClientRequest.compute_count(params[:user_ids], params[:team_identifiers], {
        detailed: params[:detailed].present?
    }, DateTime.parse(params[:from_date]), DateTime.parse(params[:to_date]))

    render json: {
        status: 'success',
        data: params[:detailed].present? ? data : {
            count: data
        }
    }
  end

  def client_request_data
    graph_type = params[:graph_type]
    graphdates = params[:graphdata]
    identifier = params[:identifier]
    userlist = params[:userlist]
    lasttodate = params[:todate].to_datetime
    todatelast = lasttodate.strftime("%Y-%m-%d")
    userdetailslist = []
    yearlydate = []
    avg_clientcount = 0
    avg_eventcount = 0
    userlist.each do |userid|
    userdetails = {}
    monthly_graphdate = []
     if graph_type == "monthly"
        fromdate = graphdates[0]
        todate = graphdates[1]
        client_requestlist = {}
        eventcount = 0
        clientcount = 0
        clientrequest = ClientRequest.where(:date=>Date.parse(fromdate)..Date.parse(todate), :user_id=>userid, :team_identifier=>identifier)
        if clientrequest.present?
            clientcount = clientrequest.count
            clientrequest.each do |client|
                if client.messages_thread.present?
                    event = client.messages_thread.event_data[:event_id] ? 1 : 0
                else
                    event = 0
                end
                eventcount += event
            end
        end    
            listdate = Date.parse(fromdate).strftime("%d-%b-%Y") + ' to ' + Date.parse(todate).strftime("%d-%b-%Y")
            client_requestlist[:date] = listdate
            client_requestlist[:clientrequest_count] = clientcount
            client_requestlist[:evnet_count] = eventcount
            
            avg_clientcount += clientcount
            avg_eventcount += eventcount
            
            monthly_graphdate.push(client_requestlist)
    else
        monthlist = graphdates - [graphdates.last]
        monthlist.each_with_index do |month, idx|
            client_requestlist = {}
            eventcount = 0
            clientcount = 0
            if idx + 1 ==  monthlist.count
                clientrequest = ClientRequest.where(:date=>Date.parse(month)..Date.parse(todatelast), :user_id=>userid, :team_identifier=>identifier)
                listdate = Date.parse(month).strftime("%d-%b-%Y") + ' to ' + Date.parse(todatelast).strftime("%d-%b-%Y")
            else    
                clientrequest = ClientRequest.where(:date=>Date.parse(month)..Date.parse(month).next_month, :user_id=>userid, :team_identifier=>identifier)
                listdate = Date.parse(month).strftime("%d-%b-%Y") + ' to ' + Date.parse(month).next_month.strftime("%d-%b-%Y")
            end
            
            if clientrequest.present?
                clientcount = clientrequest.count
                clientrequest.each do |client|
                    if client.messages_thread.present?
                        event = client.messages_thread.event_data[:event_id] ? 1 : 0
                    else
                        event = 0
                    end
                    eventcount += event
                end
            end 
            client_requestlist[:date] = listdate
            client_requestlist[:clientrequest_count] = clientcount
            client_requestlist[:evnet_count] = eventcount    
            avg_clientcount += clientcount
            avg_eventcount += eventcount
            monthly_graphdate.push(client_requestlist)
        end
    end
    userdetails[:userid] = userid
    userdetails[:clientrequest] = monthly_graphdate
    userdetailslist.push(userdetails)
    end
    render json: {
        status: 'success',
        monthlygraph: userdetailslist,
        average_client_count: avg_clientcount,
        average_event_count: avg_eventcount

        }
  end


  def client_graph_data
    graph_type = params[:graph_type]
    graphdates = params[:graphdata]
    identifier = params[:identifier]
    user_id = params[:user_id]
    monthly_graphdate = []
    todate = Time.now.strftime("%Y-%m-%d")
    average_client = ClientRequest.where(:date=>DateTime.parse(graphdates[0]).beginning_of_day..DateTime.parse(todate).end_of_day, :user_id=>user_id, :team_identifier=>identifier)
    average_count = average_client ? average_client.count : 0
    graphdates.each do |mdays|
        client_requestlist = {}
        eventcount = 0
        clientcount = 0
        clientrequest = ClientRequest.where(:date=>DateTime.parse(mdays).beginning_of_day..DateTime.parse(mdays).end_of_day, :user_id=>user_id, :team_identifier=>identifier)
        if clientrequest.present?
            clientcount = clientrequest.count
            clientrequest.each do |client|
                if client.messages_thread.present?
                    event = client.messages_thread.event_data[:event_id] ? 1 : 0
                else
                    event = 0
                end
                eventcount += event
            end
        end 
        client_requestlist[:date] = Date.parse(mdays)
        client_requestlist[:clientrequest_count] = clientcount
        client_requestlist[:evnet_count] = eventcount
        monthly_graphdate.push(client_requestlist)            
    end 
    render json: {
        status: 'success',
        monthlygraph: monthly_graphdate,
        average_count: average_count
        }
  end
end