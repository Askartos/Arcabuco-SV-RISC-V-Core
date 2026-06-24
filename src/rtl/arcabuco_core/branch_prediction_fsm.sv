module branch_prediction_fsm(
    input  logic clk,
    input  logic rst_n,
    input  logic req_event,
    input  logic answer, 
    output logic fail,
    output logic jump //out  
);

typedef enum logic [3:0]{ strong_stay = 2'b00, 
                          weak_stay   = 2'b01,
                          weak_take   = 2'b10,
                          strong_take = 2'b11} t_bpu_state;
t_bpu_state bpu_state;
logic req_event_dly,jump_dly;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        bpu_state       <= weak_stay;
        req_event_dly   <= 1'b0;
        jump_dly        <= 1'b0;
    end else begin
        req_event_dly   <= req_event;
        jump_dly        <= jump;
        if(req_event_dly)begin 
            case (bpu_state)
                strong_take :         
                    bpu_state <= fail ? weak_take : strong_take;
                weak_take   :
                    bpu_state <= fail ? weak_stay : strong_take;
                weak_stay   :
                    bpu_state <= fail ? weak_take : strong_stay;
                strong_stay :         
                    bpu_state <= fail ? weak_stay : strong_stay;
            endcase 
        end
    end
end

assign fail = req_event_dly && ( jump_dly ^ answer); //fail if different 
assign jump = bpu_state[1]; //msb indicates if branch or take 

endmodule 
