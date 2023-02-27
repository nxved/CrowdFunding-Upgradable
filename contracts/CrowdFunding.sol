// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
    @title CrowdFunding
    @author naved (https://github.com/nxved)
    @dev A contract that allows users to create crowdfunding campaigns and donate to them.
    */

contract CrowdFunding is Initializable {
    //============== STRUCT ==============
    /*
     * @dev Struct to store Campaign data
     */
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        uint256 amountDonated;
        address[] donators;
        uint256[] donations;
    }

    //============== MAPPINGS ==============
    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns;
    IERC20Upgradeable public token;

    //============== EVENTS ==============
    event CampaignCreated(
        uint256 id,
        address owner,
        string title,
        string description,
        uint256 target,
        uint256 deadline
    );
    event DonationMade(uint256 id, address donor, uint256 amount);
    event FundsClaimed(uint256 id, address owner, uint256 amount);
    event RefundClaimed(uint256 id, address donater, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //==============  FUNCTIONS ==============
    /**
        @dev initialize Function.
            */
    function initialize(address _tokenAddress) public initializer {
        token = IERC20Upgradeable(_tokenAddress);
    }

    /**
    @dev Function to Create a new crowdfunding campaign.
    @param _owner The address of the owner of the campaign.
    @param _title The title of the campaign.
    @param _description The description of the campaign.
    @param _target The target amount of the campaign.
    @param _deadline The deadline of the campaign.
    @return ID of the newly created campaign.
    */
    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline
    ) external returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];
        require(_owner != address(0), "Invalid Owner Address");
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );
        require(_target > 0, "Invalid Target Amount");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.amountDonated = 0;

        emit CampaignCreated(
            numberOfCampaigns,
            _owner,
            _title,
            _description,
            _target,
            _deadline
        );

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    /**
    @dev Function to Donate to a crowdfunding campaign.
    @param _id The ID of the campaign to donate to.
    */
    function donateToCampaign(uint256 _id, uint256 _amount) external {
        require(_amount > 0, "Incorrect Amount");

        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline > block.timestamp, "Campaign is ended.");

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfered");

        campaign.donators.push(msg.sender);
        campaign.donations.push(_amount);

        campaign.amountDonated += _amount;

        emit DonationMade(_id, msg.sender, _amount);
    }

    /**
    @dev Function to Claim the funds of a crowdfunding campaign.
    @param _id The ID of the campaign to claim funds from.
    */
    function claimFromCampaign(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.deadline < block.timestamp, "Campaign is not ended.");

        if (campaign.amountDonated >= campaign.target) {
            uint256 amount = campaign.amountDonated;
            campaign.amountDonated = 0;
            campaign.amountCollected += amount;

            bool success = token.transfer(campaign.owner, amount);
            require(success, "Token Transfered");

            emit FundsClaimed(_id, campaign.owner, amount);
        } else {
            campaign.amountDonated = 0;
            for (uint256 i = 0; i < campaign.donators.length; i++) {
                bool success = token.transfer(
                    campaign.donators[i],
                    campaign.donations[i]
                );
                require(success, "Token Transfered");
                emit RefundClaimed(
                    _id,
                    campaign.donators[i],
                    campaign.donations[i]
                );
            }
        }
    }

    /**
    @dev Function to get Donators of the perticular campaign.
    @param _id The ID of the campaign.
    */
    function getDonators(uint256 _id)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    /**
    @dev Function to all the campaigns details.
    */
    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}
