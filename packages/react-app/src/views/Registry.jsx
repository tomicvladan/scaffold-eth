import React, { useCallback, useState, useEffect } from "react";
import { downloadDataFromBee } from "./../Swarm/BeeService";

import { Link } from "react-router-dom";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import {
  Button,
  List,
  Card,
  Descriptions,
  Divider,
  Drawer,
  InputNumber,
  Modal,
  notification,
  Row,
  Col,
  Select,
  Space,
  Tooltip,
  Typography,
  Input,
} from "antd";
const { Meta } = Card;

const contractName = "COPRequestReviewRegistry";

function Registry({ writeContracts, readContracts, address, tx, localProvider }) {
  const [approvedAndFinalizedList, setApprovedAndFinalizedList] = useState([]);

  //const purpose = useContractReader(readContracts, "YourContract", "purpose");
  const approvedRequestsCount = useContractReader(readContracts, contractName, "getApprovedRequestCount");
  const approvedRequests = useContractReader(readContracts, contractName, "getApprovedRequests");
  console.log("approvedRequests", approvedRequests);

  const updateApprovedAndFinalizedRequests = useCallback(async () => {
    if (approvedRequestsCount == undefined) return;
    var list = [];

    console.log("updateApprovedAndFinalizedRequests", approvedRequestsCount.toNumber());

    for (var i = 0; i < approvedRequestsCount.toNumber(); i++) {
      var requestorAddress = await readContracts.COPRequestReviewRegistry.getApprovedRequest(i);
      //console.log("address", requestorAddress);
      var request = await readContracts.COPRequestReviewRegistry.getReviewRequest(requestorAddress);
      //console.log("request", request);

      var data = {};
      data.sender = address;
      data.reviewRequest = request;

      try {
        var requestorData = await downloadDataFromBee(request.requestorDataHash);
        data.requestorData = requestorData;
      } catch (e) {
        console.error(e);
      }
      try {
        var reviewerData = await downloadDataFromBee(request.reviewerDataHash);
        data.reviewerData = reviewerData;
      } catch (e) {
        console.error(e);
      }
      try {
        var finalizerData = await downloadDataFromBee(request.finalizerDataHash);
        data.finalizerData = finalizerData;
      } catch (e) {
        console.error(e);
      }

      list.push(data); //console.log("ReviewRequest", i, d);
    }
    setApprovedAndFinalizedList(list);
    console.log("updateApprovedAndFinalizedRequests List", data);
  });

  useEffect(() => {
    updateApprovedAndFinalizedRequests();
  }, [approvedRequestsCount]);

  if (address == undefined || approvedRequestsCount == undefined) return <h2>Connecting...</h2>;

  return (
    <div style={{ margin: "auto", width: "90vw" }}>
      {/* <List grid={{ gutter: 100, row: 10, column: 10 }}  style={{ verticalAlign: "top", display: "inline-block" }} > */}
      <Row gutter={16} type="flex">
        <Col span={24}>
          <Card hoverable title="Registry of Approved And Finalized Review Requests">
            {/* {approvedRequests} */}
            <Card.Meta
              title={"There are " + approvedRequestsCount.toNumber() + " reviewed requests"}
              description="Public registry of review requests"
            />
          </Card>
        </Col>
        <Col span={24}>
          {approvedAndFinalizedList.map((finalizedRequest, i) => (
            <Card hoverable>
              {finalizedRequest.requestorData.first} {finalizedRequest.requestorData.last}
            </Card>
          ))}
        </Col>
      </Row>
    </div>
  );
}

export default Registry;

/*
<Input
placeholder={props.placeholder ? props.placeholder : "amount in " + mode}
autoFocus={props.autoFocus}
prefix={mode === "USD" ? "$" : "Ξ"}
value={display}
addonAfter={
  !props.price ? (
    ""
  ) : (
    <div
      style={{ cursor: "pointer" }}
      onClick={() => {
        if (mode === "USD") {
          setMode("ETH");
          setDisplay(currentValue);
        } else {
          setMode("USD");
          if (currentValue) {
            const usdValue = "" + (parseFloat(currentValue) * props.price).toFixed(2);
            setDisplay(usdValue);
          } else {
            setDisplay(currentValue);
          }
        }
      }}
    >
      {mode === "USD" ? "USD 🔀" : "ETH 🔀"}
    </div>
  )
}
onChange={async e => {
  const newValue = e.target.value;
  if (mode === "USD") {
    const possibleNewValue = parseFloat(newValue);
    if (possibleNewValue) {
      const ethValue = possibleNewValue / props.price;
      setValue(ethValue);
      if (typeof props.onChange === "function") {
        props.onChange(ethValue);
      }
      setDisplay(newValue);
    } else {
      setDisplay(newValue);
    }
  } else {
    setValue(newValue);
    if (typeof props.onChange === "function") {
      props.onChange(newValue);
    }
    setDisplay(newValue);
  }
}}
/>*/
