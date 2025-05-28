// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EventTicketingSystem {
    
    struct Event {
        uint256 eventId;
        string name;
        string venue;
        uint256 date;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 ticketsSold;
        address organizer;
        bool isActive;
    }
    
    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address owner;
        bool isUsed;
        uint256 purchaseTime;
    }
    
    mapping(uint256 => Event) public events;
    mapping(uint256 => Ticket) public tickets;
    mapping(address => uint256[]) public userTickets;
    
    uint256 public eventCounter;
    uint256 public ticketCounter;
    
    event EventCreated(uint256 indexed eventId, string name, address indexed organizer);
    event TicketPurchased(uint256 indexed ticketId, uint256 indexed eventId, address indexed buyer);
    event TicketUsed(uint256 indexed ticketId, uint256 indexed eventId);
    
    modifier onlyOrganizer(uint256 _eventId) {
        require(events[_eventId].organizer == msg.sender, "Only event organizer can perform this action");
        _;
    }
    
    modifier eventExists(uint256 _eventId) {
        require(_eventId > 0 && _eventId <= eventCounter, "Event does not exist");
        _;
    }
    
    modifier ticketExists(uint256 _ticketId) {
        require(_ticketId > 0 && _ticketId <= ticketCounter, "Ticket does not exist");
        _;
    }
    
    // Core Function 1: Create Event
    function createEvent(
        string memory _name,
        string memory _venue,
        uint256 _date,
        uint256 _ticketPrice,
        uint256 _totalTickets
    ) external {
        require(bytes(_name).length > 0, "Event name cannot be empty");
        require(bytes(_venue).length > 0, "Venue cannot be empty");
        require(_date > block.timestamp, "Event date must be in the future");
        require(_ticketPrice > 0, "Ticket price must be greater than 0");
        require(_totalTickets > 0, "Total tickets must be greater than 0");
        
        eventCounter++;
        
        events[eventCounter] = Event({
            eventId: eventCounter,
            name: _name,
            venue: _venue,
            date: _date,
            ticketPrice: _ticketPrice,
            totalTickets: _totalTickets,
            ticketsSold: 0,
            organizer: msg.sender,
            isActive: true
        });
        
        emit EventCreated(eventCounter, _name, msg.sender);
    }
    
    // Core Function 2: Purchase Ticket
    function purchaseTicket(uint256 _eventId) external payable eventExists(_eventId) {
        Event storage eventData = events[_eventId];
        
        require(eventData.isActive, "Event is not active");
        require(block.timestamp < eventData.date, "Event has already occurred");
        require(eventData.ticketsSold < eventData.totalTickets, "No tickets available");
        require(msg.value == eventData.ticketPrice, "Incorrect payment amount");
        
        ticketCounter++;
        eventData.ticketsSold++;
        
        tickets[ticketCounter] = Ticket({
            ticketId: ticketCounter,
            eventId: _eventId,
            owner: msg.sender,
            isUsed: false,
            purchaseTime: block.timestamp
        });
        
        userTickets[msg.sender].push(ticketCounter);
        
        // Transfer payment to event organizer
        payable(eventData.organizer).transfer(msg.value);
        
        emit TicketPurchased(ticketCounter, _eventId, msg.sender);
    }
    
    // Core Function 3: Use Ticket (for event entry)
    function useTicket(uint256 _ticketId) external ticketExists(_ticketId) {
        Ticket storage ticket = tickets[_ticketId];
        Event storage eventData = events[ticket.eventId];
        
        require(ticket.owner == msg.sender, "You don't own this ticket");
        require(!ticket.isUsed, "Ticket has already been used");
        require(eventData.isActive, "Event is not active");
        require(block.timestamp >= eventData.date - 1 hours, "Too early to use ticket");
        require(block.timestamp <= eventData.date + 6 hours, "Event has ended");
        
        ticket.isUsed = true;
        
        emit TicketUsed(_ticketId, ticket.eventId);
    }
    
    // Additional helper functions
    function getEvent(uint256 _eventId) external view eventExists(_eventId) returns (Event memory) {
        return events[_eventId];
    }
    
    function getTicket(uint256 _ticketId) external view ticketExists(_ticketId) returns (Ticket memory) {
        return tickets[_ticketId];
    }
    
    function getUserTickets(address _user) external view returns (uint256[] memory) {
        return userTickets[_user];
    }
    
    function getAvailableTickets(uint256 _eventId) external view eventExists(_eventId) returns (uint256) {
        return events[_eventId].totalTickets - events[_eventId].ticketsSold;
    }
    
    // Emergency function for organizers
    function deactivateEvent(uint256 _eventId) external onlyOrganizer(_eventId) eventExists(_eventId) {
        events[_eventId].isActive = false;
    }
}
