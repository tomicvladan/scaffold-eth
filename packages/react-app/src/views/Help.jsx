import React, { useState, useEffect, useCallback } from "react";
import {
  Button,
  Timeline,
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
  IconText,
  Spin,
  Checkbox,
  Avatar,
} from "antd";

const questionList = [
  {
    question: "What is Datafund?",
    answer:
      "Datafund protocol is a collection of decentralized services that allows you to send and receive data objects without the need for a centralized server. It is built on top of the EVM blockchain and uses the Swarm decentralized storage.",
  },
  {
    question: "How does it work?",
    answer:
      "It uses a collection of smart contracts to store references to the Swarm decentralized storage where the contents and attachments are stored. The data in object is encrypted using the public key of the recipient and can only be decrypted by the recipient using their private key.",
  },
  {
    question: "How do I send data?",
    answer:
      "To send a data object, you need to have an MetaMask wallet and pay for the transaction fees. You can only use MetaMask wallet is it supports giving public key.",
  },
  {
    question: "How do I receive a data object?",
    answer: "To receive data object in inbox, you need to have an MetaMask wallet. ",
  },
  {
    question: "How do I receive encrypted data object?",
    answer: "To receive an encrypted data in inbox, you need to be bonded with Datafund protocol.",
  },
  {
    question: "Can I use a hardware wallet like Ledger or Trezor ?",
    answer: "No. Hardware wallets do not provide public key that is needed here.",
  },
  {
    question: "Why do I need to pay for transaction fees?",
    answer:
      "The transaction fees are paid to the network to process your transaction and to store data on Swarm. The fees are calculated based on the amount of data you are sending.",
  },
  {
    question: "What is Inbox ?",
    answer:
      "Inbox is a place where you can see all the data objects that you have received. You can not see the data that you have sent.",
  },
  {
    question: "Why Received and Sent ?",
    answer:
      "Received is a place where you can see all the two-way data that you have received. Sent is a place where you can see all the two way data that you have sent.",
  },
  {
    question: "What is the difference between Received and Inbox ?",
    answer:
      "Received is a place where you can see all the two-way data objects that you have received. Inbox is a place where you can see all the one-way data objects that you have received.",
  },
  {
    question: "What is Locker ?",
    answer: "Locker is a place where you can store your information and then share it securely if you choose so.",
  },
  {
    question: "Why Threads ?",
    answer: "Threads is a place where you can comunicate with another party in most efficient and secure way.",
  },
  {
    question: "Why Calendar ?",
    answer: "Storing your event data securely, while still other users can see your availability.",
  },

  { question: "Why Scheduler ?", answer: "Scheduler is a place where you or other users can schedule events." },
  {
    question: "Isn't Scheduler just another Calendar ?",
    answer:
      "No, Scheduler is a place where you can schedule events with others. Calendar is a place where you can store your personal event data securely, whill still allowing for others to see your availability.",
  },
  {
    question: "But Scheduler is just another Calendar ?",
    answer:
      "Scheduler supports defining start and end times for your schedule and payments per second. Calendar does not.",
  },
  {
    question: "Why incorporating Calendar and Scheduler in Smail ?",
    answer:
      "Calendar is for others to see your availability while Scheduler is your automatic scheduling machine. It's meant for AI robots to schedule events with you. Both contracts depend on encryption techinques to secure your data.",
  },
  {
    question: "Why not incorporating Calendar into Scheduler ?",
    answer:
      "Good idea. It does not make sense to have two different places for the same thing. We will do that in the future. Both contracts expose availability functions and lookup can be done so events do not overlap between your calendar and scheduled.",
  },
];

export function Help({
  readContracts,
  writeContracts,
  tx,
  userSigner,
  address,
  provider,
  smailMail,
  setSmailMail,
  web3Modal,
  onClose,
}) {
  return (
    <>
      <div
        style={{
          position: "fixed",
          top: 0,
          right: 0,
          bottom: 0,
          width: "35%",
          backgroundColor: "#40006675",
          padding: "10px",
          zIndex: 1,
        }}
      >
        <h2>
          <Button onClick={() => onClose(false)}>X</Button>&nbsp; Help
        </h2>
        <div style={{ overflowY: "scroll", height: "95%" }}>
          {questionList.map((item, index) => {
            return (
              <Card key={index}>
                <h3>{item.question}</h3>
                {item.answer}
              </Card>
            );
          })}
        </div>
      </div>
    </>
  );
}

export default Help;
