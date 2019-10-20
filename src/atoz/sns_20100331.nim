
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Notification Service
## version: 2010-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Simple Notification Service</fullname> <p>Amazon Simple Notification Service (Amazon SNS) is a web service that enables you to build distributed web-enabled applications. Applications can use Amazon SNS to easily push real-time notification messages to interested subscribers over multiple delivery protocols. For more information about this product see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. For detailed information about Amazon SNS features and their associated API calls, see the <a href="https://docs.aws.amazon.com/sns/latest/dg/">Amazon SNS Developer Guide</a>. </p> <p>We also provide SDKs that enable you to access Amazon SNS from your preferred programming language. The SDKs contain functionality that automatically takes care of tasks such as: cryptographically signing your service requests, retrying requests, and handling error responses. For a list of available SDKs, go to <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sns/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "sns.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sns.us-west-2.amazonaws.com",
                           "eu-west-2": "sns.eu-west-2.amazonaws.com", "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sns.eu-central-1.amazonaws.com",
                           "us-east-2": "sns.us-east-2.amazonaws.com",
                           "us-east-1": "sns.us-east-1.amazonaws.com", "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sns.ap-south-1.amazonaws.com",
                           "eu-north-1": "sns.eu-north-1.amazonaws.com", "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sns.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sns.eu-west-3.amazonaws.com",
                           "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sns.sa-east-1.amazonaws.com",
                           "eu-west-1": "sns.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sns.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
      "us-west-2": "sns.us-west-2.amazonaws.com",
      "eu-west-2": "sns.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sns.eu-central-1.amazonaws.com",
      "us-east-2": "sns.us-east-2.amazonaws.com",
      "us-east-1": "sns.us-east-1.amazonaws.com",
      "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sns.ap-south-1.amazonaws.com",
      "eu-north-1": "sns.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
      "us-west-1": "sns.us-west-1.amazonaws.com",
      "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sns.eu-west-3.amazonaws.com",
      "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sns.sa-east-1.amazonaws.com",
      "eu-west-1": "sns.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sns"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_592977 = ref object of OpenApiRestCall_592364
proc url_PostAddPermission_592979(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddPermission_592978(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_592980 = query.getOrDefault("Action")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_592980 != nil:
    section.add "Action", valid_592980
  var valid_592981 = query.getOrDefault("Version")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_592981 != nil:
    section.add "Version", valid_592981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592982 = header.getOrDefault("X-Amz-Signature")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Signature", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Content-Sha256", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Date")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Date", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Credential")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Credential", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Security-Token")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Security-Token", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Algorithm")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Algorithm", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-SignedHeaders", valid_592988
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_592989 = formData.getOrDefault("TopicArn")
  valid_592989 = validateParameter(valid_592989, JString, required = true,
                                 default = nil)
  if valid_592989 != nil:
    section.add "TopicArn", valid_592989
  var valid_592990 = formData.getOrDefault("AWSAccountId")
  valid_592990 = validateParameter(valid_592990, JArray, required = true, default = nil)
  if valid_592990 != nil:
    section.add "AWSAccountId", valid_592990
  var valid_592991 = formData.getOrDefault("Label")
  valid_592991 = validateParameter(valid_592991, JString, required = true,
                                 default = nil)
  if valid_592991 != nil:
    section.add "Label", valid_592991
  var valid_592992 = formData.getOrDefault("ActionName")
  valid_592992 = validateParameter(valid_592992, JArray, required = true, default = nil)
  if valid_592992 != nil:
    section.add "ActionName", valid_592992
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592993: Call_PostAddPermission_592977; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_592993.validator(path, query, header, formData, body)
  let scheme = call_592993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592993.url(scheme.get, call_592993.host, call_592993.base,
                         call_592993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592993, url, valid)

proc call*(call_592994: Call_PostAddPermission_592977; TopicArn: string;
          AWSAccountId: JsonNode; Label: string; ActionName: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## postAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Version: string (required)
  var query_592995 = newJObject()
  var formData_592996 = newJObject()
  add(formData_592996, "TopicArn", newJString(TopicArn))
  add(query_592995, "Action", newJString(Action))
  if AWSAccountId != nil:
    formData_592996.add "AWSAccountId", AWSAccountId
  add(formData_592996, "Label", newJString(Label))
  if ActionName != nil:
    formData_592996.add "ActionName", ActionName
  add(query_592995, "Version", newJString(Version))
  result = call_592994.call(nil, query_592995, nil, formData_592996, nil)

var postAddPermission* = Call_PostAddPermission_592977(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_592978,
    base: "/", url: url_PostAddPermission_592979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_592703 = ref object of OpenApiRestCall_592364
proc url_GetAddPermission_592705(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddPermission_592704(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: JString (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Version: JString (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TopicArn` field"
  var valid_592817 = query.getOrDefault("TopicArn")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = nil)
  if valid_592817 != nil:
    section.add "TopicArn", valid_592817
  var valid_592831 = query.getOrDefault("Action")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_592831 != nil:
    section.add "Action", valid_592831
  var valid_592832 = query.getOrDefault("ActionName")
  valid_592832 = validateParameter(valid_592832, JArray, required = true, default = nil)
  if valid_592832 != nil:
    section.add "ActionName", valid_592832
  var valid_592833 = query.getOrDefault("Version")
  valid_592833 = validateParameter(valid_592833, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_592833 != nil:
    section.add "Version", valid_592833
  var valid_592834 = query.getOrDefault("AWSAccountId")
  valid_592834 = validateParameter(valid_592834, JArray, required = true, default = nil)
  if valid_592834 != nil:
    section.add "AWSAccountId", valid_592834
  var valid_592835 = query.getOrDefault("Label")
  valid_592835 = validateParameter(valid_592835, JString, required = true,
                                 default = nil)
  if valid_592835 != nil:
    section.add "Label", valid_592835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592836 = header.getOrDefault("X-Amz-Signature")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Signature", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Content-Sha256", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Date")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Date", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Credential")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Credential", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Security-Token")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Security-Token", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-Algorithm")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-Algorithm", valid_592841
  var valid_592842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592842 = validateParameter(valid_592842, JString, required = false,
                                 default = nil)
  if valid_592842 != nil:
    section.add "X-Amz-SignedHeaders", valid_592842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592865: Call_GetAddPermission_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_592865.validator(path, query, header, formData, body)
  let scheme = call_592865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592865.url(scheme.get, call_592865.host, call_592865.base,
                         call_592865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592865, url, valid)

proc call*(call_592936: Call_GetAddPermission_592703; TopicArn: string;
          ActionName: JsonNode; AWSAccountId: JsonNode; Label: string;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Version: string (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  var query_592937 = newJObject()
  add(query_592937, "TopicArn", newJString(TopicArn))
  add(query_592937, "Action", newJString(Action))
  if ActionName != nil:
    query_592937.add "ActionName", ActionName
  add(query_592937, "Version", newJString(Version))
  if AWSAccountId != nil:
    query_592937.add "AWSAccountId", AWSAccountId
  add(query_592937, "Label", newJString(Label))
  result = call_592936.call(nil, query_592937, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_592703(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_592704,
    base: "/", url: url_GetAddPermission_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_593013 = ref object of OpenApiRestCall_592364
proc url_PostCheckIfPhoneNumberIsOptedOut_593015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_593014(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593016 = query.getOrDefault("Action")
  valid_593016 = validateParameter(valid_593016, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_593016 != nil:
    section.add "Action", valid_593016
  var valid_593017 = query.getOrDefault("Version")
  valid_593017 = validateParameter(valid_593017, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593017 != nil:
    section.add "Version", valid_593017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593018 = header.getOrDefault("X-Amz-Signature")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Signature", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Content-Sha256", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Date")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Date", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Credential")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Credential", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Security-Token")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Security-Token", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Algorithm")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Algorithm", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-SignedHeaders", valid_593024
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_593025 = formData.getOrDefault("phoneNumber")
  valid_593025 = validateParameter(valid_593025, JString, required = true,
                                 default = nil)
  if valid_593025 != nil:
    section.add "phoneNumber", valid_593025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593026: Call_PostCheckIfPhoneNumberIsOptedOut_593013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_593026.validator(path, query, header, formData, body)
  let scheme = call_593026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593026.url(scheme.get, call_593026.host, call_593026.base,
                         call_593026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593026, url, valid)

proc call*(call_593027: Call_PostCheckIfPhoneNumberIsOptedOut_593013;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593028 = newJObject()
  var formData_593029 = newJObject()
  add(formData_593029, "phoneNumber", newJString(phoneNumber))
  add(query_593028, "Action", newJString(Action))
  add(query_593028, "Version", newJString(Version))
  result = call_593027.call(nil, query_593028, nil, formData_593029, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_593013(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_593014, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_593015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_592997 = ref object of OpenApiRestCall_592364
proc url_GetCheckIfPhoneNumberIsOptedOut_592999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_592998(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_593000 = query.getOrDefault("phoneNumber")
  valid_593000 = validateParameter(valid_593000, JString, required = true,
                                 default = nil)
  if valid_593000 != nil:
    section.add "phoneNumber", valid_593000
  var valid_593001 = query.getOrDefault("Action")
  valid_593001 = validateParameter(valid_593001, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_593001 != nil:
    section.add "Action", valid_593001
  var valid_593002 = query.getOrDefault("Version")
  valid_593002 = validateParameter(valid_593002, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593002 != nil:
    section.add "Version", valid_593002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593003 = header.getOrDefault("X-Amz-Signature")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Signature", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Content-Sha256", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Date")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Date", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Credential")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Credential", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Security-Token")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Security-Token", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Algorithm")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Algorithm", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-SignedHeaders", valid_593009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593010: Call_GetCheckIfPhoneNumberIsOptedOut_592997;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_593010.validator(path, query, header, formData, body)
  let scheme = call_593010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593010.url(scheme.get, call_593010.host, call_593010.base,
                         call_593010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593010, url, valid)

proc call*(call_593011: Call_GetCheckIfPhoneNumberIsOptedOut_592997;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593012 = newJObject()
  add(query_593012, "phoneNumber", newJString(phoneNumber))
  add(query_593012, "Action", newJString(Action))
  add(query_593012, "Version", newJString(Version))
  result = call_593011.call(nil, query_593012, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_592997(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_592998, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_592999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_593048 = ref object of OpenApiRestCall_592364
proc url_PostConfirmSubscription_593050(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostConfirmSubscription_593049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593051 = query.getOrDefault("Action")
  valid_593051 = validateParameter(valid_593051, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_593051 != nil:
    section.add "Action", valid_593051
  var valid_593052 = query.getOrDefault("Version")
  valid_593052 = validateParameter(valid_593052, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593052 != nil:
    section.add "Version", valid_593052
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593053 = header.getOrDefault("X-Amz-Signature")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Signature", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Content-Sha256", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Date")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Date", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Credential")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Credential", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Security-Token")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Security-Token", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-Algorithm")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-Algorithm", valid_593058
  var valid_593059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-SignedHeaders", valid_593059
  result.add "header", section
  ## parameters in `formData` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  var valid_593060 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_593060
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_593061 = formData.getOrDefault("TopicArn")
  valid_593061 = validateParameter(valid_593061, JString, required = true,
                                 default = nil)
  if valid_593061 != nil:
    section.add "TopicArn", valid_593061
  var valid_593062 = formData.getOrDefault("Token")
  valid_593062 = validateParameter(valid_593062, JString, required = true,
                                 default = nil)
  if valid_593062 != nil:
    section.add "Token", valid_593062
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593063: Call_PostConfirmSubscription_593048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_593063.validator(path, query, header, formData, body)
  let scheme = call_593063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593063.url(scheme.get, call_593063.host, call_593063.base,
                         call_593063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593063, url, valid)

proc call*(call_593064: Call_PostConfirmSubscription_593048; TopicArn: string;
          Token: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## postConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593065 = newJObject()
  var formData_593066 = newJObject()
  add(formData_593066, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(formData_593066, "TopicArn", newJString(TopicArn))
  add(formData_593066, "Token", newJString(Token))
  add(query_593065, "Action", newJString(Action))
  add(query_593065, "Version", newJString(Version))
  result = call_593064.call(nil, query_593065, nil, formData_593066, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_593048(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_593049, base: "/",
    url: url_PostConfirmSubscription_593050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_593030 = ref object of OpenApiRestCall_592364
proc url_GetConfirmSubscription_593032(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetConfirmSubscription_593031(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  section = newJObject()
  var valid_593033 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_593033
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_593034 = query.getOrDefault("Token")
  valid_593034 = validateParameter(valid_593034, JString, required = true,
                                 default = nil)
  if valid_593034 != nil:
    section.add "Token", valid_593034
  var valid_593035 = query.getOrDefault("Action")
  valid_593035 = validateParameter(valid_593035, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_593035 != nil:
    section.add "Action", valid_593035
  var valid_593036 = query.getOrDefault("Version")
  valid_593036 = validateParameter(valid_593036, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593036 != nil:
    section.add "Version", valid_593036
  var valid_593037 = query.getOrDefault("TopicArn")
  valid_593037 = validateParameter(valid_593037, JString, required = true,
                                 default = nil)
  if valid_593037 != nil:
    section.add "TopicArn", valid_593037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593038 = header.getOrDefault("X-Amz-Signature")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Signature", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Content-Sha256", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Date")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Date", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Credential")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Credential", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Security-Token")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Security-Token", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-Algorithm")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-Algorithm", valid_593043
  var valid_593044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-SignedHeaders", valid_593044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593045: Call_GetConfirmSubscription_593030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_593045.validator(path, query, header, formData, body)
  let scheme = call_593045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593045.url(scheme.get, call_593045.host, call_593045.base,
                         call_593045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593045, url, valid)

proc call*(call_593046: Call_GetConfirmSubscription_593030; Token: string;
          TopicArn: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## getConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  var query_593047 = newJObject()
  add(query_593047, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_593047, "Token", newJString(Token))
  add(query_593047, "Action", newJString(Action))
  add(query_593047, "Version", newJString(Version))
  add(query_593047, "TopicArn", newJString(TopicArn))
  result = call_593046.call(nil, query_593047, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_593030(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_593031, base: "/",
    url: url_GetConfirmSubscription_593032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_593090 = ref object of OpenApiRestCall_592364
proc url_PostCreatePlatformApplication_593092(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformApplication_593091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593093 = query.getOrDefault("Action")
  valid_593093 = validateParameter(valid_593093, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_593093 != nil:
    section.add "Action", valid_593093
  var valid_593094 = query.getOrDefault("Version")
  valid_593094 = validateParameter(valid_593094, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593094 != nil:
    section.add "Version", valid_593094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593095 = header.getOrDefault("X-Amz-Signature")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Signature", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Content-Sha256", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Date")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Date", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Credential")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Credential", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Security-Token")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Security-Token", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-Algorithm")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Algorithm", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-SignedHeaders", valid_593101
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_593102 = formData.getOrDefault("Attributes.0.key")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "Attributes.0.key", valid_593102
  assert formData != nil,
        "formData argument is necessary due to required `Platform` field"
  var valid_593103 = formData.getOrDefault("Platform")
  valid_593103 = validateParameter(valid_593103, JString, required = true,
                                 default = nil)
  if valid_593103 != nil:
    section.add "Platform", valid_593103
  var valid_593104 = formData.getOrDefault("Attributes.2.value")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "Attributes.2.value", valid_593104
  var valid_593105 = formData.getOrDefault("Attributes.2.key")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "Attributes.2.key", valid_593105
  var valid_593106 = formData.getOrDefault("Attributes.0.value")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "Attributes.0.value", valid_593106
  var valid_593107 = formData.getOrDefault("Attributes.1.key")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "Attributes.1.key", valid_593107
  var valid_593108 = formData.getOrDefault("Name")
  valid_593108 = validateParameter(valid_593108, JString, required = true,
                                 default = nil)
  if valid_593108 != nil:
    section.add "Name", valid_593108
  var valid_593109 = formData.getOrDefault("Attributes.1.value")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "Attributes.1.value", valid_593109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593110: Call_PostCreatePlatformApplication_593090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_593110.validator(path, query, header, formData, body)
  let scheme = call_593110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593110.url(scheme.get, call_593110.host, call_593110.base,
                         call_593110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593110, url, valid)

proc call*(call_593111: Call_PostCreatePlatformApplication_593090;
          Platform: string; Name: string; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Attributes0Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_593112 = newJObject()
  var formData_593113 = newJObject()
  add(formData_593113, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_593113, "Platform", newJString(Platform))
  add(formData_593113, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_593113, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_593113, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_593113, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593112, "Action", newJString(Action))
  add(formData_593113, "Name", newJString(Name))
  add(query_593112, "Version", newJString(Version))
  add(formData_593113, "Attributes.1.value", newJString(Attributes1Value))
  result = call_593111.call(nil, query_593112, nil, formData_593113, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_593090(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_593091, base: "/",
    url: url_PostCreatePlatformApplication_593092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_593067 = ref object of OpenApiRestCall_592364
proc url_GetCreatePlatformApplication_593069(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformApplication_593068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_593070 = query.getOrDefault("Attributes.1.key")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "Attributes.1.key", valid_593070
  var valid_593071 = query.getOrDefault("Attributes.0.value")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "Attributes.0.value", valid_593071
  var valid_593072 = query.getOrDefault("Attributes.0.key")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "Attributes.0.key", valid_593072
  assert query != nil,
        "query argument is necessary due to required `Platform` field"
  var valid_593073 = query.getOrDefault("Platform")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = nil)
  if valid_593073 != nil:
    section.add "Platform", valid_593073
  var valid_593074 = query.getOrDefault("Attributes.2.value")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "Attributes.2.value", valid_593074
  var valid_593075 = query.getOrDefault("Attributes.1.value")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "Attributes.1.value", valid_593075
  var valid_593076 = query.getOrDefault("Name")
  valid_593076 = validateParameter(valid_593076, JString, required = true,
                                 default = nil)
  if valid_593076 != nil:
    section.add "Name", valid_593076
  var valid_593077 = query.getOrDefault("Action")
  valid_593077 = validateParameter(valid_593077, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_593077 != nil:
    section.add "Action", valid_593077
  var valid_593078 = query.getOrDefault("Version")
  valid_593078 = validateParameter(valid_593078, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593078 != nil:
    section.add "Version", valid_593078
  var valid_593079 = query.getOrDefault("Attributes.2.key")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "Attributes.2.key", valid_593079
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593080 = header.getOrDefault("X-Amz-Signature")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Signature", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Content-Sha256", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Date")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Date", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Credential")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Credential", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Security-Token")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Security-Token", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Algorithm")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Algorithm", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-SignedHeaders", valid_593086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593087: Call_GetCreatePlatformApplication_593067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_593087.validator(path, query, header, formData, body)
  let scheme = call_593087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593087.url(scheme.get, call_593087.host, call_593087.base,
                         call_593087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593087, url, valid)

proc call*(call_593088: Call_GetCreatePlatformApplication_593067; Platform: string;
          Name: string; Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = "";
          Action: string = "CreatePlatformApplication";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_593089 = newJObject()
  add(query_593089, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593089, "Attributes.0.value", newJString(Attributes0Value))
  add(query_593089, "Attributes.0.key", newJString(Attributes0Key))
  add(query_593089, "Platform", newJString(Platform))
  add(query_593089, "Attributes.2.value", newJString(Attributes2Value))
  add(query_593089, "Attributes.1.value", newJString(Attributes1Value))
  add(query_593089, "Name", newJString(Name))
  add(query_593089, "Action", newJString(Action))
  add(query_593089, "Version", newJString(Version))
  add(query_593089, "Attributes.2.key", newJString(Attributes2Key))
  result = call_593088.call(nil, query_593089, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_593067(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_593068, base: "/",
    url: url_GetCreatePlatformApplication_593069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_593138 = ref object of OpenApiRestCall_592364
proc url_PostCreatePlatformEndpoint_593140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformEndpoint_593139(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593141 = query.getOrDefault("Action")
  valid_593141 = validateParameter(valid_593141, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_593141 != nil:
    section.add "Action", valid_593141
  var valid_593142 = query.getOrDefault("Version")
  valid_593142 = validateParameter(valid_593142, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593142 != nil:
    section.add "Version", valid_593142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593143 = header.getOrDefault("X-Amz-Signature")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Signature", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Content-Sha256", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Date")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Date", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Credential")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Credential", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Security-Token")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Security-Token", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Algorithm")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Algorithm", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-SignedHeaders", valid_593149
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593150 = formData.getOrDefault("PlatformApplicationArn")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "PlatformApplicationArn", valid_593150
  var valid_593151 = formData.getOrDefault("CustomUserData")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "CustomUserData", valid_593151
  var valid_593152 = formData.getOrDefault("Attributes.0.key")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "Attributes.0.key", valid_593152
  var valid_593153 = formData.getOrDefault("Attributes.2.value")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "Attributes.2.value", valid_593153
  var valid_593154 = formData.getOrDefault("Attributes.2.key")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "Attributes.2.key", valid_593154
  var valid_593155 = formData.getOrDefault("Attributes.0.value")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "Attributes.0.value", valid_593155
  var valid_593156 = formData.getOrDefault("Attributes.1.key")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "Attributes.1.key", valid_593156
  var valid_593157 = formData.getOrDefault("Token")
  valid_593157 = validateParameter(valid_593157, JString, required = true,
                                 default = nil)
  if valid_593157 != nil:
    section.add "Token", valid_593157
  var valid_593158 = formData.getOrDefault("Attributes.1.value")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "Attributes.1.value", valid_593158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593159: Call_PostCreatePlatformEndpoint_593138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_593159.validator(path, query, header, formData, body)
  let scheme = call_593159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593159.url(scheme.get, call_593159.host, call_593159.base,
                         call_593159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593159, url, valid)

proc call*(call_593160: Call_PostCreatePlatformEndpoint_593138;
          PlatformApplicationArn: string; Token: string;
          CustomUserData: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformEndpoint"; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_593161 = newJObject()
  var formData_593162 = newJObject()
  add(formData_593162, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_593162, "CustomUserData", newJString(CustomUserData))
  add(formData_593162, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_593162, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_593162, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_593162, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_593162, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_593162, "Token", newJString(Token))
  add(query_593161, "Action", newJString(Action))
  add(query_593161, "Version", newJString(Version))
  add(formData_593162, "Attributes.1.value", newJString(Attributes1Value))
  result = call_593160.call(nil, query_593161, nil, formData_593162, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_593138(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_593139, base: "/",
    url: url_PostCreatePlatformEndpoint_593140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_593114 = ref object of OpenApiRestCall_592364
proc url_GetCreatePlatformEndpoint_593116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformEndpoint_593115(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_593117 = query.getOrDefault("Attributes.1.key")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "Attributes.1.key", valid_593117
  var valid_593118 = query.getOrDefault("CustomUserData")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "CustomUserData", valid_593118
  var valid_593119 = query.getOrDefault("Attributes.0.value")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "Attributes.0.value", valid_593119
  var valid_593120 = query.getOrDefault("Attributes.0.key")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "Attributes.0.key", valid_593120
  var valid_593121 = query.getOrDefault("Attributes.2.value")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "Attributes.2.value", valid_593121
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_593122 = query.getOrDefault("Token")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = nil)
  if valid_593122 != nil:
    section.add "Token", valid_593122
  var valid_593123 = query.getOrDefault("Attributes.1.value")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "Attributes.1.value", valid_593123
  var valid_593124 = query.getOrDefault("PlatformApplicationArn")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = nil)
  if valid_593124 != nil:
    section.add "PlatformApplicationArn", valid_593124
  var valid_593125 = query.getOrDefault("Action")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_593125 != nil:
    section.add "Action", valid_593125
  var valid_593126 = query.getOrDefault("Version")
  valid_593126 = validateParameter(valid_593126, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593126 != nil:
    section.add "Version", valid_593126
  var valid_593127 = query.getOrDefault("Attributes.2.key")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "Attributes.2.key", valid_593127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593128 = header.getOrDefault("X-Amz-Signature")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Signature", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Content-Sha256", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Date")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Date", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Credential")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Credential", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Security-Token")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Security-Token", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Algorithm")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Algorithm", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-SignedHeaders", valid_593134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593135: Call_GetCreatePlatformEndpoint_593114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_593135.validator(path, query, header, formData, body)
  let scheme = call_593135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593135.url(scheme.get, call_593135.host, call_593135.base,
                         call_593135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593135, url, valid)

proc call*(call_593136: Call_GetCreatePlatformEndpoint_593114; Token: string;
          PlatformApplicationArn: string; Attributes1Key: string = "";
          CustomUserData: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   Attributes1Key: string
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_593137 = newJObject()
  add(query_593137, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593137, "CustomUserData", newJString(CustomUserData))
  add(query_593137, "Attributes.0.value", newJString(Attributes0Value))
  add(query_593137, "Attributes.0.key", newJString(Attributes0Key))
  add(query_593137, "Attributes.2.value", newJString(Attributes2Value))
  add(query_593137, "Token", newJString(Token))
  add(query_593137, "Attributes.1.value", newJString(Attributes1Value))
  add(query_593137, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_593137, "Action", newJString(Action))
  add(query_593137, "Version", newJString(Version))
  add(query_593137, "Attributes.2.key", newJString(Attributes2Key))
  result = call_593136.call(nil, query_593137, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_593114(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_593115, base: "/",
    url: url_GetCreatePlatformEndpoint_593116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_593186 = ref object of OpenApiRestCall_592364
proc url_PostCreateTopic_593188(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateTopic_593187(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593189 = query.getOrDefault("Action")
  valid_593189 = validateParameter(valid_593189, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_593189 != nil:
    section.add "Action", valid_593189
  var valid_593190 = query.getOrDefault("Version")
  valid_593190 = validateParameter(valid_593190, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593190 != nil:
    section.add "Version", valid_593190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593191 = header.getOrDefault("X-Amz-Signature")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Signature", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Content-Sha256", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Date")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Date", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Credential")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Credential", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Security-Token")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Security-Token", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Algorithm")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Algorithm", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-SignedHeaders", valid_593197
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_593198 = formData.getOrDefault("Attributes.0.key")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "Attributes.0.key", valid_593198
  var valid_593199 = formData.getOrDefault("Attributes.2.value")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "Attributes.2.value", valid_593199
  var valid_593200 = formData.getOrDefault("Attributes.2.key")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "Attributes.2.key", valid_593200
  var valid_593201 = formData.getOrDefault("Attributes.0.value")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "Attributes.0.value", valid_593201
  var valid_593202 = formData.getOrDefault("Attributes.1.key")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "Attributes.1.key", valid_593202
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_593203 = formData.getOrDefault("Name")
  valid_593203 = validateParameter(valid_593203, JString, required = true,
                                 default = nil)
  if valid_593203 != nil:
    section.add "Name", valid_593203
  var valid_593204 = formData.getOrDefault("Tags")
  valid_593204 = validateParameter(valid_593204, JArray, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "Tags", valid_593204
  var valid_593205 = formData.getOrDefault("Attributes.1.value")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "Attributes.1.value", valid_593205
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593206: Call_PostCreateTopic_593186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_593206.validator(path, query, header, formData, body)
  let scheme = call_593206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593206.url(scheme.get, call_593206.host, call_593206.base,
                         call_593206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593206, url, valid)

proc call*(call_593207: Call_PostCreateTopic_593186; Name: string;
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Attributes0Value: string = "";
          Attributes1Key: string = ""; Action: string = "CreateTopic";
          Tags: JsonNode = nil; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_593208 = newJObject()
  var formData_593209 = newJObject()
  add(formData_593209, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_593209, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_593209, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_593209, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_593209, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593208, "Action", newJString(Action))
  add(formData_593209, "Name", newJString(Name))
  if Tags != nil:
    formData_593209.add "Tags", Tags
  add(query_593208, "Version", newJString(Version))
  add(formData_593209, "Attributes.1.value", newJString(Attributes1Value))
  result = call_593207.call(nil, query_593208, nil, formData_593209, nil)

var postCreateTopic* = Call_PostCreateTopic_593186(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_593187,
    base: "/", url: url_PostCreateTopic_593188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_593163 = ref object of OpenApiRestCall_592364
proc url_GetCreateTopic_593165(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateTopic_593164(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_593166 = query.getOrDefault("Attributes.1.key")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "Attributes.1.key", valid_593166
  var valid_593167 = query.getOrDefault("Attributes.0.value")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "Attributes.0.value", valid_593167
  var valid_593168 = query.getOrDefault("Attributes.0.key")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "Attributes.0.key", valid_593168
  var valid_593169 = query.getOrDefault("Tags")
  valid_593169 = validateParameter(valid_593169, JArray, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "Tags", valid_593169
  var valid_593170 = query.getOrDefault("Attributes.2.value")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "Attributes.2.value", valid_593170
  var valid_593171 = query.getOrDefault("Attributes.1.value")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "Attributes.1.value", valid_593171
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_593172 = query.getOrDefault("Name")
  valid_593172 = validateParameter(valid_593172, JString, required = true,
                                 default = nil)
  if valid_593172 != nil:
    section.add "Name", valid_593172
  var valid_593173 = query.getOrDefault("Action")
  valid_593173 = validateParameter(valid_593173, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_593173 != nil:
    section.add "Action", valid_593173
  var valid_593174 = query.getOrDefault("Version")
  valid_593174 = validateParameter(valid_593174, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593174 != nil:
    section.add "Version", valid_593174
  var valid_593175 = query.getOrDefault("Attributes.2.key")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "Attributes.2.key", valid_593175
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593176 = header.getOrDefault("X-Amz-Signature")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Signature", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Content-Sha256", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Date")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Date", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Credential")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Credential", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Security-Token")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Security-Token", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Algorithm")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Algorithm", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-SignedHeaders", valid_593182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593183: Call_GetCreateTopic_593163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_593183.validator(path, query, header, formData, body)
  let scheme = call_593183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593183.url(scheme.get, call_593183.host, call_593183.base,
                         call_593183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593183, url, valid)

proc call*(call_593184: Call_GetCreateTopic_593163; Name: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Tags: JsonNode = nil;
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "CreateTopic"; Version: string = "2010-03-31";
          Attributes2Key: string = ""): Recallable =
  ## getCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_593185 = newJObject()
  add(query_593185, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593185, "Attributes.0.value", newJString(Attributes0Value))
  add(query_593185, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    query_593185.add "Tags", Tags
  add(query_593185, "Attributes.2.value", newJString(Attributes2Value))
  add(query_593185, "Attributes.1.value", newJString(Attributes1Value))
  add(query_593185, "Name", newJString(Name))
  add(query_593185, "Action", newJString(Action))
  add(query_593185, "Version", newJString(Version))
  add(query_593185, "Attributes.2.key", newJString(Attributes2Key))
  result = call_593184.call(nil, query_593185, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_593163(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_593164,
    base: "/", url: url_GetCreateTopic_593165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_593226 = ref object of OpenApiRestCall_592364
proc url_PostDeleteEndpoint_593228(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEndpoint_593227(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593229 = query.getOrDefault("Action")
  valid_593229 = validateParameter(valid_593229, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_593229 != nil:
    section.add "Action", valid_593229
  var valid_593230 = query.getOrDefault("Version")
  valid_593230 = validateParameter(valid_593230, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593230 != nil:
    section.add "Version", valid_593230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593231 = header.getOrDefault("X-Amz-Signature")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Signature", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Content-Sha256", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Date")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Date", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Credential")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Credential", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Security-Token")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Security-Token", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Algorithm")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Algorithm", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-SignedHeaders", valid_593237
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_593238 = formData.getOrDefault("EndpointArn")
  valid_593238 = validateParameter(valid_593238, JString, required = true,
                                 default = nil)
  if valid_593238 != nil:
    section.add "EndpointArn", valid_593238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593239: Call_PostDeleteEndpoint_593226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_593239.validator(path, query, header, formData, body)
  let scheme = call_593239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593239.url(scheme.get, call_593239.host, call_593239.base,
                         call_593239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593239, url, valid)

proc call*(call_593240: Call_PostDeleteEndpoint_593226; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593241 = newJObject()
  var formData_593242 = newJObject()
  add(formData_593242, "EndpointArn", newJString(EndpointArn))
  add(query_593241, "Action", newJString(Action))
  add(query_593241, "Version", newJString(Version))
  result = call_593240.call(nil, query_593241, nil, formData_593242, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_593226(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_593227, base: "/",
    url: url_PostDeleteEndpoint_593228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_593210 = ref object of OpenApiRestCall_592364
proc url_GetDeleteEndpoint_593212(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEndpoint_593211(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593213 = query.getOrDefault("Action")
  valid_593213 = validateParameter(valid_593213, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_593213 != nil:
    section.add "Action", valid_593213
  var valid_593214 = query.getOrDefault("EndpointArn")
  valid_593214 = validateParameter(valid_593214, JString, required = true,
                                 default = nil)
  if valid_593214 != nil:
    section.add "EndpointArn", valid_593214
  var valid_593215 = query.getOrDefault("Version")
  valid_593215 = validateParameter(valid_593215, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593215 != nil:
    section.add "Version", valid_593215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593216 = header.getOrDefault("X-Amz-Signature")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Signature", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Content-Sha256", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Date")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Date", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Credential")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Credential", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Security-Token")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Security-Token", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Algorithm")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Algorithm", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-SignedHeaders", valid_593222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593223: Call_GetDeleteEndpoint_593210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_593223.validator(path, query, header, formData, body)
  let scheme = call_593223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593223.url(scheme.get, call_593223.host, call_593223.base,
                         call_593223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593223, url, valid)

proc call*(call_593224: Call_GetDeleteEndpoint_593210; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_593225 = newJObject()
  add(query_593225, "Action", newJString(Action))
  add(query_593225, "EndpointArn", newJString(EndpointArn))
  add(query_593225, "Version", newJString(Version))
  result = call_593224.call(nil, query_593225, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_593210(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_593211,
    base: "/", url: url_GetDeleteEndpoint_593212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_593259 = ref object of OpenApiRestCall_592364
proc url_PostDeletePlatformApplication_593261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformApplication_593260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593262 = query.getOrDefault("Action")
  valid_593262 = validateParameter(valid_593262, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_593262 != nil:
    section.add "Action", valid_593262
  var valid_593263 = query.getOrDefault("Version")
  valid_593263 = validateParameter(valid_593263, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593263 != nil:
    section.add "Version", valid_593263
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593264 = header.getOrDefault("X-Amz-Signature")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Signature", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Content-Sha256", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Date")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Date", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Credential")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Credential", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Security-Token")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Security-Token", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-Algorithm")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-Algorithm", valid_593269
  var valid_593270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "X-Amz-SignedHeaders", valid_593270
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593271 = formData.getOrDefault("PlatformApplicationArn")
  valid_593271 = validateParameter(valid_593271, JString, required = true,
                                 default = nil)
  if valid_593271 != nil:
    section.add "PlatformApplicationArn", valid_593271
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593272: Call_PostDeletePlatformApplication_593259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593272.validator(path, query, header, formData, body)
  let scheme = call_593272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593272.url(scheme.get, call_593272.host, call_593272.base,
                         call_593272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593272, url, valid)

proc call*(call_593273: Call_PostDeletePlatformApplication_593259;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593274 = newJObject()
  var formData_593275 = newJObject()
  add(formData_593275, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_593274, "Action", newJString(Action))
  add(query_593274, "Version", newJString(Version))
  result = call_593273.call(nil, query_593274, nil, formData_593275, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_593259(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_593260, base: "/",
    url: url_PostDeletePlatformApplication_593261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_593243 = ref object of OpenApiRestCall_592364
proc url_GetDeletePlatformApplication_593245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformApplication_593244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593246 = query.getOrDefault("PlatformApplicationArn")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = nil)
  if valid_593246 != nil:
    section.add "PlatformApplicationArn", valid_593246
  var valid_593247 = query.getOrDefault("Action")
  valid_593247 = validateParameter(valid_593247, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_593247 != nil:
    section.add "Action", valid_593247
  var valid_593248 = query.getOrDefault("Version")
  valid_593248 = validateParameter(valid_593248, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593248 != nil:
    section.add "Version", valid_593248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593249 = header.getOrDefault("X-Amz-Signature")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Signature", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Content-Sha256", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Date")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Date", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Credential")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Credential", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Security-Token")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Security-Token", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-Algorithm")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-Algorithm", valid_593254
  var valid_593255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "X-Amz-SignedHeaders", valid_593255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593256: Call_GetDeletePlatformApplication_593243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593256.validator(path, query, header, formData, body)
  let scheme = call_593256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593256.url(scheme.get, call_593256.host, call_593256.base,
                         call_593256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593256, url, valid)

proc call*(call_593257: Call_GetDeletePlatformApplication_593243;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593258 = newJObject()
  add(query_593258, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_593258, "Action", newJString(Action))
  add(query_593258, "Version", newJString(Version))
  result = call_593257.call(nil, query_593258, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_593243(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_593244, base: "/",
    url: url_GetDeletePlatformApplication_593245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_593292 = ref object of OpenApiRestCall_592364
proc url_PostDeleteTopic_593294(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteTopic_593293(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593295 = query.getOrDefault("Action")
  valid_593295 = validateParameter(valid_593295, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_593295 != nil:
    section.add "Action", valid_593295
  var valid_593296 = query.getOrDefault("Version")
  valid_593296 = validateParameter(valid_593296, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593296 != nil:
    section.add "Version", valid_593296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593297 = header.getOrDefault("X-Amz-Signature")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Signature", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Content-Sha256", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Date")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Date", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Credential")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Credential", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Security-Token")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Security-Token", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Algorithm")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Algorithm", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-SignedHeaders", valid_593303
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_593304 = formData.getOrDefault("TopicArn")
  valid_593304 = validateParameter(valid_593304, JString, required = true,
                                 default = nil)
  if valid_593304 != nil:
    section.add "TopicArn", valid_593304
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593305: Call_PostDeleteTopic_593292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_593305.validator(path, query, header, formData, body)
  let scheme = call_593305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593305.url(scheme.get, call_593305.host, call_593305.base,
                         call_593305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593305, url, valid)

proc call*(call_593306: Call_PostDeleteTopic_593292; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593307 = newJObject()
  var formData_593308 = newJObject()
  add(formData_593308, "TopicArn", newJString(TopicArn))
  add(query_593307, "Action", newJString(Action))
  add(query_593307, "Version", newJString(Version))
  result = call_593306.call(nil, query_593307, nil, formData_593308, nil)

var postDeleteTopic* = Call_PostDeleteTopic_593292(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_593293,
    base: "/", url: url_PostDeleteTopic_593294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_593276 = ref object of OpenApiRestCall_592364
proc url_GetDeleteTopic_593278(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteTopic_593277(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593279 = query.getOrDefault("Action")
  valid_593279 = validateParameter(valid_593279, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_593279 != nil:
    section.add "Action", valid_593279
  var valid_593280 = query.getOrDefault("Version")
  valid_593280 = validateParameter(valid_593280, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593280 != nil:
    section.add "Version", valid_593280
  var valid_593281 = query.getOrDefault("TopicArn")
  valid_593281 = validateParameter(valid_593281, JString, required = true,
                                 default = nil)
  if valid_593281 != nil:
    section.add "TopicArn", valid_593281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593282 = header.getOrDefault("X-Amz-Signature")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Signature", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Content-Sha256", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Date")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Date", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Credential")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Credential", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Security-Token")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Security-Token", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Algorithm")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Algorithm", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-SignedHeaders", valid_593288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593289: Call_GetDeleteTopic_593276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_593289.validator(path, query, header, formData, body)
  let scheme = call_593289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593289.url(scheme.get, call_593289.host, call_593289.base,
                         call_593289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593289, url, valid)

proc call*(call_593290: Call_GetDeleteTopic_593276; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  var query_593291 = newJObject()
  add(query_593291, "Action", newJString(Action))
  add(query_593291, "Version", newJString(Version))
  add(query_593291, "TopicArn", newJString(TopicArn))
  result = call_593290.call(nil, query_593291, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_593276(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_593277,
    base: "/", url: url_GetDeleteTopic_593278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_593325 = ref object of OpenApiRestCall_592364
proc url_PostGetEndpointAttributes_593327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetEndpointAttributes_593326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593328 = query.getOrDefault("Action")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_593328 != nil:
    section.add "Action", valid_593328
  var valid_593329 = query.getOrDefault("Version")
  valid_593329 = validateParameter(valid_593329, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593329 != nil:
    section.add "Version", valid_593329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593330 = header.getOrDefault("X-Amz-Signature")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Signature", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Content-Sha256", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Date")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Date", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Credential")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Credential", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Security-Token")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Security-Token", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Algorithm")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Algorithm", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-SignedHeaders", valid_593336
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_593337 = formData.getOrDefault("EndpointArn")
  valid_593337 = validateParameter(valid_593337, JString, required = true,
                                 default = nil)
  if valid_593337 != nil:
    section.add "EndpointArn", valid_593337
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593338: Call_PostGetEndpointAttributes_593325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593338.validator(path, query, header, formData, body)
  let scheme = call_593338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593338.url(scheme.get, call_593338.host, call_593338.base,
                         call_593338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593338, url, valid)

proc call*(call_593339: Call_PostGetEndpointAttributes_593325; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593340 = newJObject()
  var formData_593341 = newJObject()
  add(formData_593341, "EndpointArn", newJString(EndpointArn))
  add(query_593340, "Action", newJString(Action))
  add(query_593340, "Version", newJString(Version))
  result = call_593339.call(nil, query_593340, nil, formData_593341, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_593325(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_593326, base: "/",
    url: url_PostGetEndpointAttributes_593327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_593309 = ref object of OpenApiRestCall_592364
proc url_GetGetEndpointAttributes_593311(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetEndpointAttributes_593310(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593312 = query.getOrDefault("Action")
  valid_593312 = validateParameter(valid_593312, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_593312 != nil:
    section.add "Action", valid_593312
  var valid_593313 = query.getOrDefault("EndpointArn")
  valid_593313 = validateParameter(valid_593313, JString, required = true,
                                 default = nil)
  if valid_593313 != nil:
    section.add "EndpointArn", valid_593313
  var valid_593314 = query.getOrDefault("Version")
  valid_593314 = validateParameter(valid_593314, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593314 != nil:
    section.add "Version", valid_593314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593315 = header.getOrDefault("X-Amz-Signature")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-Signature", valid_593315
  var valid_593316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593316 = validateParameter(valid_593316, JString, required = false,
                                 default = nil)
  if valid_593316 != nil:
    section.add "X-Amz-Content-Sha256", valid_593316
  var valid_593317 = header.getOrDefault("X-Amz-Date")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Date", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Credential")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Credential", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Security-Token")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Security-Token", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Algorithm")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Algorithm", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-SignedHeaders", valid_593321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593322: Call_GetGetEndpointAttributes_593309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593322.validator(path, query, header, formData, body)
  let scheme = call_593322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593322.url(scheme.get, call_593322.host, call_593322.base,
                         call_593322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593322, url, valid)

proc call*(call_593323: Call_GetGetEndpointAttributes_593309; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_593324 = newJObject()
  add(query_593324, "Action", newJString(Action))
  add(query_593324, "EndpointArn", newJString(EndpointArn))
  add(query_593324, "Version", newJString(Version))
  result = call_593323.call(nil, query_593324, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_593309(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_593310, base: "/",
    url: url_GetGetEndpointAttributes_593311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_593358 = ref object of OpenApiRestCall_592364
proc url_PostGetPlatformApplicationAttributes_593360(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_593359(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593361 = query.getOrDefault("Action")
  valid_593361 = validateParameter(valid_593361, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_593361 != nil:
    section.add "Action", valid_593361
  var valid_593362 = query.getOrDefault("Version")
  valid_593362 = validateParameter(valid_593362, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593362 != nil:
    section.add "Version", valid_593362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593363 = header.getOrDefault("X-Amz-Signature")
  valid_593363 = validateParameter(valid_593363, JString, required = false,
                                 default = nil)
  if valid_593363 != nil:
    section.add "X-Amz-Signature", valid_593363
  var valid_593364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593364 = validateParameter(valid_593364, JString, required = false,
                                 default = nil)
  if valid_593364 != nil:
    section.add "X-Amz-Content-Sha256", valid_593364
  var valid_593365 = header.getOrDefault("X-Amz-Date")
  valid_593365 = validateParameter(valid_593365, JString, required = false,
                                 default = nil)
  if valid_593365 != nil:
    section.add "X-Amz-Date", valid_593365
  var valid_593366 = header.getOrDefault("X-Amz-Credential")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Credential", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Security-Token")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Security-Token", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Algorithm")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Algorithm", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-SignedHeaders", valid_593369
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593370 = formData.getOrDefault("PlatformApplicationArn")
  valid_593370 = validateParameter(valid_593370, JString, required = true,
                                 default = nil)
  if valid_593370 != nil:
    section.add "PlatformApplicationArn", valid_593370
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593371: Call_PostGetPlatformApplicationAttributes_593358;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593371.validator(path, query, header, formData, body)
  let scheme = call_593371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593371.url(scheme.get, call_593371.host, call_593371.base,
                         call_593371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593371, url, valid)

proc call*(call_593372: Call_PostGetPlatformApplicationAttributes_593358;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593373 = newJObject()
  var formData_593374 = newJObject()
  add(formData_593374, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_593373, "Action", newJString(Action))
  add(query_593373, "Version", newJString(Version))
  result = call_593372.call(nil, query_593373, nil, formData_593374, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_593358(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_593359, base: "/",
    url: url_PostGetPlatformApplicationAttributes_593360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_593342 = ref object of OpenApiRestCall_592364
proc url_GetGetPlatformApplicationAttributes_593344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetPlatformApplicationAttributes_593343(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593345 = query.getOrDefault("PlatformApplicationArn")
  valid_593345 = validateParameter(valid_593345, JString, required = true,
                                 default = nil)
  if valid_593345 != nil:
    section.add "PlatformApplicationArn", valid_593345
  var valid_593346 = query.getOrDefault("Action")
  valid_593346 = validateParameter(valid_593346, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_593346 != nil:
    section.add "Action", valid_593346
  var valid_593347 = query.getOrDefault("Version")
  valid_593347 = validateParameter(valid_593347, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593347 != nil:
    section.add "Version", valid_593347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593348 = header.getOrDefault("X-Amz-Signature")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Signature", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Content-Sha256", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-Date")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-Date", valid_593350
  var valid_593351 = header.getOrDefault("X-Amz-Credential")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Credential", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Security-Token")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Security-Token", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Algorithm")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Algorithm", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-SignedHeaders", valid_593354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593355: Call_GetGetPlatformApplicationAttributes_593342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593355.validator(path, query, header, formData, body)
  let scheme = call_593355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593355.url(scheme.get, call_593355.host, call_593355.base,
                         call_593355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593355, url, valid)

proc call*(call_593356: Call_GetGetPlatformApplicationAttributes_593342;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593357 = newJObject()
  add(query_593357, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_593357, "Action", newJString(Action))
  add(query_593357, "Version", newJString(Version))
  result = call_593356.call(nil, query_593357, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_593342(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_593343, base: "/",
    url: url_GetGetPlatformApplicationAttributes_593344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_593391 = ref object of OpenApiRestCall_592364
proc url_PostGetSMSAttributes_593393(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetSMSAttributes_593392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593394 = query.getOrDefault("Action")
  valid_593394 = validateParameter(valid_593394, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_593394 != nil:
    section.add "Action", valid_593394
  var valid_593395 = query.getOrDefault("Version")
  valid_593395 = validateParameter(valid_593395, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593395 != nil:
    section.add "Version", valid_593395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593396 = header.getOrDefault("X-Amz-Signature")
  valid_593396 = validateParameter(valid_593396, JString, required = false,
                                 default = nil)
  if valid_593396 != nil:
    section.add "X-Amz-Signature", valid_593396
  var valid_593397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593397 = validateParameter(valid_593397, JString, required = false,
                                 default = nil)
  if valid_593397 != nil:
    section.add "X-Amz-Content-Sha256", valid_593397
  var valid_593398 = header.getOrDefault("X-Amz-Date")
  valid_593398 = validateParameter(valid_593398, JString, required = false,
                                 default = nil)
  if valid_593398 != nil:
    section.add "X-Amz-Date", valid_593398
  var valid_593399 = header.getOrDefault("X-Amz-Credential")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Credential", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Security-Token")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Security-Token", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Algorithm")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Algorithm", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-SignedHeaders", valid_593402
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_593403 = formData.getOrDefault("attributes")
  valid_593403 = validateParameter(valid_593403, JArray, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "attributes", valid_593403
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593404: Call_PostGetSMSAttributes_593391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_593404.validator(path, query, header, formData, body)
  let scheme = call_593404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593404.url(scheme.get, call_593404.host, call_593404.base,
                         call_593404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593404, url, valid)

proc call*(call_593405: Call_PostGetSMSAttributes_593391;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593406 = newJObject()
  var formData_593407 = newJObject()
  if attributes != nil:
    formData_593407.add "attributes", attributes
  add(query_593406, "Action", newJString(Action))
  add(query_593406, "Version", newJString(Version))
  result = call_593405.call(nil, query_593406, nil, formData_593407, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_593391(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_593392, base: "/",
    url: url_PostGetSMSAttributes_593393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_593375 = ref object of OpenApiRestCall_592364
proc url_GetGetSMSAttributes_593377(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetSMSAttributes_593376(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593378 = query.getOrDefault("Action")
  valid_593378 = validateParameter(valid_593378, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_593378 != nil:
    section.add "Action", valid_593378
  var valid_593379 = query.getOrDefault("attributes")
  valid_593379 = validateParameter(valid_593379, JArray, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "attributes", valid_593379
  var valid_593380 = query.getOrDefault("Version")
  valid_593380 = validateParameter(valid_593380, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593380 != nil:
    section.add "Version", valid_593380
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593381 = header.getOrDefault("X-Amz-Signature")
  valid_593381 = validateParameter(valid_593381, JString, required = false,
                                 default = nil)
  if valid_593381 != nil:
    section.add "X-Amz-Signature", valid_593381
  var valid_593382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Content-Sha256", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Date")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Date", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Credential")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Credential", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Security-Token")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Security-Token", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Algorithm")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Algorithm", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-SignedHeaders", valid_593387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593388: Call_GetGetSMSAttributes_593375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_593388.validator(path, query, header, formData, body)
  let scheme = call_593388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593388.url(scheme.get, call_593388.host, call_593388.base,
                         call_593388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593388, url, valid)

proc call*(call_593389: Call_GetGetSMSAttributes_593375;
          Action: string = "GetSMSAttributes"; attributes: JsonNode = nil;
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   Action: string (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: string (required)
  var query_593390 = newJObject()
  add(query_593390, "Action", newJString(Action))
  if attributes != nil:
    query_593390.add "attributes", attributes
  add(query_593390, "Version", newJString(Version))
  result = call_593389.call(nil, query_593390, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_593375(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_593376, base: "/",
    url: url_GetGetSMSAttributes_593377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_593424 = ref object of OpenApiRestCall_592364
proc url_PostGetSubscriptionAttributes_593426(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetSubscriptionAttributes_593425(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593427 = query.getOrDefault("Action")
  valid_593427 = validateParameter(valid_593427, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_593427 != nil:
    section.add "Action", valid_593427
  var valid_593428 = query.getOrDefault("Version")
  valid_593428 = validateParameter(valid_593428, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593428 != nil:
    section.add "Version", valid_593428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593429 = header.getOrDefault("X-Amz-Signature")
  valid_593429 = validateParameter(valid_593429, JString, required = false,
                                 default = nil)
  if valid_593429 != nil:
    section.add "X-Amz-Signature", valid_593429
  var valid_593430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Content-Sha256", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Date")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Date", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Credential")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Credential", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Security-Token")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Security-Token", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Algorithm")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Algorithm", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-SignedHeaders", valid_593435
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_593436 = formData.getOrDefault("SubscriptionArn")
  valid_593436 = validateParameter(valid_593436, JString, required = true,
                                 default = nil)
  if valid_593436 != nil:
    section.add "SubscriptionArn", valid_593436
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593437: Call_PostGetSubscriptionAttributes_593424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_593437.validator(path, query, header, formData, body)
  let scheme = call_593437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593437.url(scheme.get, call_593437.host, call_593437.base,
                         call_593437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593437, url, valid)

proc call*(call_593438: Call_PostGetSubscriptionAttributes_593424;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593439 = newJObject()
  var formData_593440 = newJObject()
  add(formData_593440, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_593439, "Action", newJString(Action))
  add(query_593439, "Version", newJString(Version))
  result = call_593438.call(nil, query_593439, nil, formData_593440, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_593424(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_593425, base: "/",
    url: url_PostGetSubscriptionAttributes_593426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_593408 = ref object of OpenApiRestCall_592364
proc url_GetGetSubscriptionAttributes_593410(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetSubscriptionAttributes_593409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_593411 = query.getOrDefault("SubscriptionArn")
  valid_593411 = validateParameter(valid_593411, JString, required = true,
                                 default = nil)
  if valid_593411 != nil:
    section.add "SubscriptionArn", valid_593411
  var valid_593412 = query.getOrDefault("Action")
  valid_593412 = validateParameter(valid_593412, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_593412 != nil:
    section.add "Action", valid_593412
  var valid_593413 = query.getOrDefault("Version")
  valid_593413 = validateParameter(valid_593413, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593413 != nil:
    section.add "Version", valid_593413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593414 = header.getOrDefault("X-Amz-Signature")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Signature", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Content-Sha256", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Date")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Date", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Credential")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Credential", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Security-Token")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Security-Token", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Algorithm")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Algorithm", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-SignedHeaders", valid_593420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593421: Call_GetGetSubscriptionAttributes_593408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_593421.validator(path, query, header, formData, body)
  let scheme = call_593421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593421.url(scheme.get, call_593421.host, call_593421.base,
                         call_593421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593421, url, valid)

proc call*(call_593422: Call_GetGetSubscriptionAttributes_593408;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593423 = newJObject()
  add(query_593423, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_593423, "Action", newJString(Action))
  add(query_593423, "Version", newJString(Version))
  result = call_593422.call(nil, query_593423, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_593408(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_593409, base: "/",
    url: url_GetGetSubscriptionAttributes_593410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_593457 = ref object of OpenApiRestCall_592364
proc url_PostGetTopicAttributes_593459(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetTopicAttributes_593458(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593460 = query.getOrDefault("Action")
  valid_593460 = validateParameter(valid_593460, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_593460 != nil:
    section.add "Action", valid_593460
  var valid_593461 = query.getOrDefault("Version")
  valid_593461 = validateParameter(valid_593461, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593461 != nil:
    section.add "Version", valid_593461
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593462 = header.getOrDefault("X-Amz-Signature")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Signature", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Content-Sha256", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Date")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Date", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Credential")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Credential", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Security-Token")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Security-Token", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Algorithm")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Algorithm", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-SignedHeaders", valid_593468
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_593469 = formData.getOrDefault("TopicArn")
  valid_593469 = validateParameter(valid_593469, JString, required = true,
                                 default = nil)
  if valid_593469 != nil:
    section.add "TopicArn", valid_593469
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593470: Call_PostGetTopicAttributes_593457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_593470.validator(path, query, header, formData, body)
  let scheme = call_593470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593470.url(scheme.get, call_593470.host, call_593470.base,
                         call_593470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593470, url, valid)

proc call*(call_593471: Call_PostGetTopicAttributes_593457; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593472 = newJObject()
  var formData_593473 = newJObject()
  add(formData_593473, "TopicArn", newJString(TopicArn))
  add(query_593472, "Action", newJString(Action))
  add(query_593472, "Version", newJString(Version))
  result = call_593471.call(nil, query_593472, nil, formData_593473, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_593457(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_593458, base: "/",
    url: url_PostGetTopicAttributes_593459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_593441 = ref object of OpenApiRestCall_592364
proc url_GetGetTopicAttributes_593443(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetTopicAttributes_593442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593444 = query.getOrDefault("Action")
  valid_593444 = validateParameter(valid_593444, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_593444 != nil:
    section.add "Action", valid_593444
  var valid_593445 = query.getOrDefault("Version")
  valid_593445 = validateParameter(valid_593445, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593445 != nil:
    section.add "Version", valid_593445
  var valid_593446 = query.getOrDefault("TopicArn")
  valid_593446 = validateParameter(valid_593446, JString, required = true,
                                 default = nil)
  if valid_593446 != nil:
    section.add "TopicArn", valid_593446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593447 = header.getOrDefault("X-Amz-Signature")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Signature", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Content-Sha256", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Date")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Date", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Credential")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Credential", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Security-Token")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Security-Token", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Algorithm")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Algorithm", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-SignedHeaders", valid_593453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593454: Call_GetGetTopicAttributes_593441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_593454.validator(path, query, header, formData, body)
  let scheme = call_593454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593454.url(scheme.get, call_593454.host, call_593454.base,
                         call_593454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593454, url, valid)

proc call*(call_593455: Call_GetGetTopicAttributes_593441; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  var query_593456 = newJObject()
  add(query_593456, "Action", newJString(Action))
  add(query_593456, "Version", newJString(Version))
  add(query_593456, "TopicArn", newJString(TopicArn))
  result = call_593455.call(nil, query_593456, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_593441(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_593442, base: "/",
    url: url_GetGetTopicAttributes_593443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_593491 = ref object of OpenApiRestCall_592364
proc url_PostListEndpointsByPlatformApplication_593493(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_593492(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593494 = query.getOrDefault("Action")
  valid_593494 = validateParameter(valid_593494, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_593494 != nil:
    section.add "Action", valid_593494
  var valid_593495 = query.getOrDefault("Version")
  valid_593495 = validateParameter(valid_593495, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593495 != nil:
    section.add "Version", valid_593495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593496 = header.getOrDefault("X-Amz-Signature")
  valid_593496 = validateParameter(valid_593496, JString, required = false,
                                 default = nil)
  if valid_593496 != nil:
    section.add "X-Amz-Signature", valid_593496
  var valid_593497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593497 = validateParameter(valid_593497, JString, required = false,
                                 default = nil)
  if valid_593497 != nil:
    section.add "X-Amz-Content-Sha256", valid_593497
  var valid_593498 = header.getOrDefault("X-Amz-Date")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Date", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Credential")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Credential", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Security-Token")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Security-Token", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Algorithm")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Algorithm", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-SignedHeaders", valid_593502
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593503 = formData.getOrDefault("PlatformApplicationArn")
  valid_593503 = validateParameter(valid_593503, JString, required = true,
                                 default = nil)
  if valid_593503 != nil:
    section.add "PlatformApplicationArn", valid_593503
  var valid_593504 = formData.getOrDefault("NextToken")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "NextToken", valid_593504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593505: Call_PostListEndpointsByPlatformApplication_593491;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593505.validator(path, query, header, formData, body)
  let scheme = call_593505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593505.url(scheme.get, call_593505.host, call_593505.base,
                         call_593505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593505, url, valid)

proc call*(call_593506: Call_PostListEndpointsByPlatformApplication_593491;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593507 = newJObject()
  var formData_593508 = newJObject()
  add(formData_593508, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_593508, "NextToken", newJString(NextToken))
  add(query_593507, "Action", newJString(Action))
  add(query_593507, "Version", newJString(Version))
  result = call_593506.call(nil, query_593507, nil, formData_593508, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_593491(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_593492, base: "/",
    url: url_PostListEndpointsByPlatformApplication_593493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_593474 = ref object of OpenApiRestCall_592364
proc url_GetListEndpointsByPlatformApplication_593476(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_593475(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593477 = query.getOrDefault("NextToken")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "NextToken", valid_593477
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593478 = query.getOrDefault("PlatformApplicationArn")
  valid_593478 = validateParameter(valid_593478, JString, required = true,
                                 default = nil)
  if valid_593478 != nil:
    section.add "PlatformApplicationArn", valid_593478
  var valid_593479 = query.getOrDefault("Action")
  valid_593479 = validateParameter(valid_593479, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_593479 != nil:
    section.add "Action", valid_593479
  var valid_593480 = query.getOrDefault("Version")
  valid_593480 = validateParameter(valid_593480, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593480 != nil:
    section.add "Version", valid_593480
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593481 = header.getOrDefault("X-Amz-Signature")
  valid_593481 = validateParameter(valid_593481, JString, required = false,
                                 default = nil)
  if valid_593481 != nil:
    section.add "X-Amz-Signature", valid_593481
  var valid_593482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593482 = validateParameter(valid_593482, JString, required = false,
                                 default = nil)
  if valid_593482 != nil:
    section.add "X-Amz-Content-Sha256", valid_593482
  var valid_593483 = header.getOrDefault("X-Amz-Date")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Date", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Credential")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Credential", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Security-Token")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Security-Token", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Algorithm")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Algorithm", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-SignedHeaders", valid_593487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593488: Call_GetListEndpointsByPlatformApplication_593474;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593488.validator(path, query, header, formData, body)
  let scheme = call_593488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593488.url(scheme.get, call_593488.host, call_593488.base,
                         call_593488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593488, url, valid)

proc call*(call_593489: Call_GetListEndpointsByPlatformApplication_593474;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593490 = newJObject()
  add(query_593490, "NextToken", newJString(NextToken))
  add(query_593490, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_593490, "Action", newJString(Action))
  add(query_593490, "Version", newJString(Version))
  result = call_593489.call(nil, query_593490, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_593474(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_593475, base: "/",
    url: url_GetListEndpointsByPlatformApplication_593476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_593525 = ref object of OpenApiRestCall_592364
proc url_PostListPhoneNumbersOptedOut_593527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPhoneNumbersOptedOut_593526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593528 = query.getOrDefault("Action")
  valid_593528 = validateParameter(valid_593528, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_593528 != nil:
    section.add "Action", valid_593528
  var valid_593529 = query.getOrDefault("Version")
  valid_593529 = validateParameter(valid_593529, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593529 != nil:
    section.add "Version", valid_593529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593530 = header.getOrDefault("X-Amz-Signature")
  valid_593530 = validateParameter(valid_593530, JString, required = false,
                                 default = nil)
  if valid_593530 != nil:
    section.add "X-Amz-Signature", valid_593530
  var valid_593531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593531 = validateParameter(valid_593531, JString, required = false,
                                 default = nil)
  if valid_593531 != nil:
    section.add "X-Amz-Content-Sha256", valid_593531
  var valid_593532 = header.getOrDefault("X-Amz-Date")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Date", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Credential")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Credential", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Security-Token")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Security-Token", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Algorithm")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Algorithm", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-SignedHeaders", valid_593536
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_593537 = formData.getOrDefault("nextToken")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "nextToken", valid_593537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593538: Call_PostListPhoneNumbersOptedOut_593525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_593538.validator(path, query, header, formData, body)
  let scheme = call_593538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593538.url(scheme.get, call_593538.host, call_593538.base,
                         call_593538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593538, url, valid)

proc call*(call_593539: Call_PostListPhoneNumbersOptedOut_593525;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593540 = newJObject()
  var formData_593541 = newJObject()
  add(formData_593541, "nextToken", newJString(nextToken))
  add(query_593540, "Action", newJString(Action))
  add(query_593540, "Version", newJString(Version))
  result = call_593539.call(nil, query_593540, nil, formData_593541, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_593525(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_593526, base: "/",
    url: url_PostListPhoneNumbersOptedOut_593527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_593509 = ref object of OpenApiRestCall_592364
proc url_GetListPhoneNumbersOptedOut_593511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPhoneNumbersOptedOut_593510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593512 = query.getOrDefault("nextToken")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "nextToken", valid_593512
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593513 = query.getOrDefault("Action")
  valid_593513 = validateParameter(valid_593513, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_593513 != nil:
    section.add "Action", valid_593513
  var valid_593514 = query.getOrDefault("Version")
  valid_593514 = validateParameter(valid_593514, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593514 != nil:
    section.add "Version", valid_593514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593515 = header.getOrDefault("X-Amz-Signature")
  valid_593515 = validateParameter(valid_593515, JString, required = false,
                                 default = nil)
  if valid_593515 != nil:
    section.add "X-Amz-Signature", valid_593515
  var valid_593516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593516 = validateParameter(valid_593516, JString, required = false,
                                 default = nil)
  if valid_593516 != nil:
    section.add "X-Amz-Content-Sha256", valid_593516
  var valid_593517 = header.getOrDefault("X-Amz-Date")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Date", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Credential")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Credential", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Security-Token")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Security-Token", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Algorithm")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Algorithm", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-SignedHeaders", valid_593521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593522: Call_GetListPhoneNumbersOptedOut_593509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_593522.validator(path, query, header, formData, body)
  let scheme = call_593522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593522.url(scheme.get, call_593522.host, call_593522.base,
                         call_593522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593522, url, valid)

proc call*(call_593523: Call_GetListPhoneNumbersOptedOut_593509;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593524 = newJObject()
  add(query_593524, "nextToken", newJString(nextToken))
  add(query_593524, "Action", newJString(Action))
  add(query_593524, "Version", newJString(Version))
  result = call_593523.call(nil, query_593524, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_593509(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_593510, base: "/",
    url: url_GetListPhoneNumbersOptedOut_593511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_593558 = ref object of OpenApiRestCall_592364
proc url_PostListPlatformApplications_593560(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformApplications_593559(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593561 = query.getOrDefault("Action")
  valid_593561 = validateParameter(valid_593561, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_593561 != nil:
    section.add "Action", valid_593561
  var valid_593562 = query.getOrDefault("Version")
  valid_593562 = validateParameter(valid_593562, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593562 != nil:
    section.add "Version", valid_593562
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593563 = header.getOrDefault("X-Amz-Signature")
  valid_593563 = validateParameter(valid_593563, JString, required = false,
                                 default = nil)
  if valid_593563 != nil:
    section.add "X-Amz-Signature", valid_593563
  var valid_593564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593564 = validateParameter(valid_593564, JString, required = false,
                                 default = nil)
  if valid_593564 != nil:
    section.add "X-Amz-Content-Sha256", valid_593564
  var valid_593565 = header.getOrDefault("X-Amz-Date")
  valid_593565 = validateParameter(valid_593565, JString, required = false,
                                 default = nil)
  if valid_593565 != nil:
    section.add "X-Amz-Date", valid_593565
  var valid_593566 = header.getOrDefault("X-Amz-Credential")
  valid_593566 = validateParameter(valid_593566, JString, required = false,
                                 default = nil)
  if valid_593566 != nil:
    section.add "X-Amz-Credential", valid_593566
  var valid_593567 = header.getOrDefault("X-Amz-Security-Token")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Security-Token", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Algorithm")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Algorithm", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-SignedHeaders", valid_593569
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_593570 = formData.getOrDefault("NextToken")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "NextToken", valid_593570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593571: Call_PostListPlatformApplications_593558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_593571.validator(path, query, header, formData, body)
  let scheme = call_593571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593571.url(scheme.get, call_593571.host, call_593571.base,
                         call_593571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593571, url, valid)

proc call*(call_593572: Call_PostListPlatformApplications_593558;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593573 = newJObject()
  var formData_593574 = newJObject()
  add(formData_593574, "NextToken", newJString(NextToken))
  add(query_593573, "Action", newJString(Action))
  add(query_593573, "Version", newJString(Version))
  result = call_593572.call(nil, query_593573, nil, formData_593574, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_593558(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_593559, base: "/",
    url: url_PostListPlatformApplications_593560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_593542 = ref object of OpenApiRestCall_592364
proc url_GetListPlatformApplications_593544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformApplications_593543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593545 = query.getOrDefault("NextToken")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "NextToken", valid_593545
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593546 = query.getOrDefault("Action")
  valid_593546 = validateParameter(valid_593546, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_593546 != nil:
    section.add "Action", valid_593546
  var valid_593547 = query.getOrDefault("Version")
  valid_593547 = validateParameter(valid_593547, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593547 != nil:
    section.add "Version", valid_593547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593548 = header.getOrDefault("X-Amz-Signature")
  valid_593548 = validateParameter(valid_593548, JString, required = false,
                                 default = nil)
  if valid_593548 != nil:
    section.add "X-Amz-Signature", valid_593548
  var valid_593549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593549 = validateParameter(valid_593549, JString, required = false,
                                 default = nil)
  if valid_593549 != nil:
    section.add "X-Amz-Content-Sha256", valid_593549
  var valid_593550 = header.getOrDefault("X-Amz-Date")
  valid_593550 = validateParameter(valid_593550, JString, required = false,
                                 default = nil)
  if valid_593550 != nil:
    section.add "X-Amz-Date", valid_593550
  var valid_593551 = header.getOrDefault("X-Amz-Credential")
  valid_593551 = validateParameter(valid_593551, JString, required = false,
                                 default = nil)
  if valid_593551 != nil:
    section.add "X-Amz-Credential", valid_593551
  var valid_593552 = header.getOrDefault("X-Amz-Security-Token")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Security-Token", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Algorithm")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Algorithm", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-SignedHeaders", valid_593554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593555: Call_GetListPlatformApplications_593542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_593555.validator(path, query, header, formData, body)
  let scheme = call_593555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593555.url(scheme.get, call_593555.host, call_593555.base,
                         call_593555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593555, url, valid)

proc call*(call_593556: Call_GetListPlatformApplications_593542;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593557 = newJObject()
  add(query_593557, "NextToken", newJString(NextToken))
  add(query_593557, "Action", newJString(Action))
  add(query_593557, "Version", newJString(Version))
  result = call_593556.call(nil, query_593557, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_593542(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_593543, base: "/",
    url: url_GetListPlatformApplications_593544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_593591 = ref object of OpenApiRestCall_592364
proc url_PostListSubscriptions_593593(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListSubscriptions_593592(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593594 = query.getOrDefault("Action")
  valid_593594 = validateParameter(valid_593594, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_593594 != nil:
    section.add "Action", valid_593594
  var valid_593595 = query.getOrDefault("Version")
  valid_593595 = validateParameter(valid_593595, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593595 != nil:
    section.add "Version", valid_593595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593596 = header.getOrDefault("X-Amz-Signature")
  valid_593596 = validateParameter(valid_593596, JString, required = false,
                                 default = nil)
  if valid_593596 != nil:
    section.add "X-Amz-Signature", valid_593596
  var valid_593597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593597 = validateParameter(valid_593597, JString, required = false,
                                 default = nil)
  if valid_593597 != nil:
    section.add "X-Amz-Content-Sha256", valid_593597
  var valid_593598 = header.getOrDefault("X-Amz-Date")
  valid_593598 = validateParameter(valid_593598, JString, required = false,
                                 default = nil)
  if valid_593598 != nil:
    section.add "X-Amz-Date", valid_593598
  var valid_593599 = header.getOrDefault("X-Amz-Credential")
  valid_593599 = validateParameter(valid_593599, JString, required = false,
                                 default = nil)
  if valid_593599 != nil:
    section.add "X-Amz-Credential", valid_593599
  var valid_593600 = header.getOrDefault("X-Amz-Security-Token")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "X-Amz-Security-Token", valid_593600
  var valid_593601 = header.getOrDefault("X-Amz-Algorithm")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "X-Amz-Algorithm", valid_593601
  var valid_593602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-SignedHeaders", valid_593602
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_593603 = formData.getOrDefault("NextToken")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "NextToken", valid_593603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593604: Call_PostListSubscriptions_593591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593604.validator(path, query, header, formData, body)
  let scheme = call_593604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593604.url(scheme.get, call_593604.host, call_593604.base,
                         call_593604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593604, url, valid)

proc call*(call_593605: Call_PostListSubscriptions_593591; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593606 = newJObject()
  var formData_593607 = newJObject()
  add(formData_593607, "NextToken", newJString(NextToken))
  add(query_593606, "Action", newJString(Action))
  add(query_593606, "Version", newJString(Version))
  result = call_593605.call(nil, query_593606, nil, formData_593607, nil)

var postListSubscriptions* = Call_PostListSubscriptions_593591(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_593592, base: "/",
    url: url_PostListSubscriptions_593593, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_593575 = ref object of OpenApiRestCall_592364
proc url_GetListSubscriptions_593577(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListSubscriptions_593576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593578 = query.getOrDefault("NextToken")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "NextToken", valid_593578
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593579 = query.getOrDefault("Action")
  valid_593579 = validateParameter(valid_593579, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_593579 != nil:
    section.add "Action", valid_593579
  var valid_593580 = query.getOrDefault("Version")
  valid_593580 = validateParameter(valid_593580, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593580 != nil:
    section.add "Version", valid_593580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593581 = header.getOrDefault("X-Amz-Signature")
  valid_593581 = validateParameter(valid_593581, JString, required = false,
                                 default = nil)
  if valid_593581 != nil:
    section.add "X-Amz-Signature", valid_593581
  var valid_593582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593582 = validateParameter(valid_593582, JString, required = false,
                                 default = nil)
  if valid_593582 != nil:
    section.add "X-Amz-Content-Sha256", valid_593582
  var valid_593583 = header.getOrDefault("X-Amz-Date")
  valid_593583 = validateParameter(valid_593583, JString, required = false,
                                 default = nil)
  if valid_593583 != nil:
    section.add "X-Amz-Date", valid_593583
  var valid_593584 = header.getOrDefault("X-Amz-Credential")
  valid_593584 = validateParameter(valid_593584, JString, required = false,
                                 default = nil)
  if valid_593584 != nil:
    section.add "X-Amz-Credential", valid_593584
  var valid_593585 = header.getOrDefault("X-Amz-Security-Token")
  valid_593585 = validateParameter(valid_593585, JString, required = false,
                                 default = nil)
  if valid_593585 != nil:
    section.add "X-Amz-Security-Token", valid_593585
  var valid_593586 = header.getOrDefault("X-Amz-Algorithm")
  valid_593586 = validateParameter(valid_593586, JString, required = false,
                                 default = nil)
  if valid_593586 != nil:
    section.add "X-Amz-Algorithm", valid_593586
  var valid_593587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-SignedHeaders", valid_593587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593588: Call_GetListSubscriptions_593575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593588.validator(path, query, header, formData, body)
  let scheme = call_593588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593588.url(scheme.get, call_593588.host, call_593588.base,
                         call_593588.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593588, url, valid)

proc call*(call_593589: Call_GetListSubscriptions_593575; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593590 = newJObject()
  add(query_593590, "NextToken", newJString(NextToken))
  add(query_593590, "Action", newJString(Action))
  add(query_593590, "Version", newJString(Version))
  result = call_593589.call(nil, query_593590, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_593575(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_593576, base: "/",
    url: url_GetListSubscriptions_593577, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_593625 = ref object of OpenApiRestCall_592364
proc url_PostListSubscriptionsByTopic_593627(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListSubscriptionsByTopic_593626(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593628 = query.getOrDefault("Action")
  valid_593628 = validateParameter(valid_593628, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_593628 != nil:
    section.add "Action", valid_593628
  var valid_593629 = query.getOrDefault("Version")
  valid_593629 = validateParameter(valid_593629, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593629 != nil:
    section.add "Version", valid_593629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593630 = header.getOrDefault("X-Amz-Signature")
  valid_593630 = validateParameter(valid_593630, JString, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "X-Amz-Signature", valid_593630
  var valid_593631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "X-Amz-Content-Sha256", valid_593631
  var valid_593632 = header.getOrDefault("X-Amz-Date")
  valid_593632 = validateParameter(valid_593632, JString, required = false,
                                 default = nil)
  if valid_593632 != nil:
    section.add "X-Amz-Date", valid_593632
  var valid_593633 = header.getOrDefault("X-Amz-Credential")
  valid_593633 = validateParameter(valid_593633, JString, required = false,
                                 default = nil)
  if valid_593633 != nil:
    section.add "X-Amz-Credential", valid_593633
  var valid_593634 = header.getOrDefault("X-Amz-Security-Token")
  valid_593634 = validateParameter(valid_593634, JString, required = false,
                                 default = nil)
  if valid_593634 != nil:
    section.add "X-Amz-Security-Token", valid_593634
  var valid_593635 = header.getOrDefault("X-Amz-Algorithm")
  valid_593635 = validateParameter(valid_593635, JString, required = false,
                                 default = nil)
  if valid_593635 != nil:
    section.add "X-Amz-Algorithm", valid_593635
  var valid_593636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593636 = validateParameter(valid_593636, JString, required = false,
                                 default = nil)
  if valid_593636 != nil:
    section.add "X-Amz-SignedHeaders", valid_593636
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_593637 = formData.getOrDefault("NextToken")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "NextToken", valid_593637
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_593638 = formData.getOrDefault("TopicArn")
  valid_593638 = validateParameter(valid_593638, JString, required = true,
                                 default = nil)
  if valid_593638 != nil:
    section.add "TopicArn", valid_593638
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593639: Call_PostListSubscriptionsByTopic_593625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593639.validator(path, query, header, formData, body)
  let scheme = call_593639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593639.url(scheme.get, call_593639.host, call_593639.base,
                         call_593639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593639, url, valid)

proc call*(call_593640: Call_PostListSubscriptionsByTopic_593625; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593641 = newJObject()
  var formData_593642 = newJObject()
  add(formData_593642, "NextToken", newJString(NextToken))
  add(formData_593642, "TopicArn", newJString(TopicArn))
  add(query_593641, "Action", newJString(Action))
  add(query_593641, "Version", newJString(Version))
  result = call_593640.call(nil, query_593641, nil, formData_593642, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_593625(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_593626, base: "/",
    url: url_PostListSubscriptionsByTopic_593627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_593608 = ref object of OpenApiRestCall_592364
proc url_GetListSubscriptionsByTopic_593610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListSubscriptionsByTopic_593609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_593611 = query.getOrDefault("NextToken")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "NextToken", valid_593611
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593612 = query.getOrDefault("Action")
  valid_593612 = validateParameter(valid_593612, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_593612 != nil:
    section.add "Action", valid_593612
  var valid_593613 = query.getOrDefault("Version")
  valid_593613 = validateParameter(valid_593613, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593613 != nil:
    section.add "Version", valid_593613
  var valid_593614 = query.getOrDefault("TopicArn")
  valid_593614 = validateParameter(valid_593614, JString, required = true,
                                 default = nil)
  if valid_593614 != nil:
    section.add "TopicArn", valid_593614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593615 = header.getOrDefault("X-Amz-Signature")
  valid_593615 = validateParameter(valid_593615, JString, required = false,
                                 default = nil)
  if valid_593615 != nil:
    section.add "X-Amz-Signature", valid_593615
  var valid_593616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593616 = validateParameter(valid_593616, JString, required = false,
                                 default = nil)
  if valid_593616 != nil:
    section.add "X-Amz-Content-Sha256", valid_593616
  var valid_593617 = header.getOrDefault("X-Amz-Date")
  valid_593617 = validateParameter(valid_593617, JString, required = false,
                                 default = nil)
  if valid_593617 != nil:
    section.add "X-Amz-Date", valid_593617
  var valid_593618 = header.getOrDefault("X-Amz-Credential")
  valid_593618 = validateParameter(valid_593618, JString, required = false,
                                 default = nil)
  if valid_593618 != nil:
    section.add "X-Amz-Credential", valid_593618
  var valid_593619 = header.getOrDefault("X-Amz-Security-Token")
  valid_593619 = validateParameter(valid_593619, JString, required = false,
                                 default = nil)
  if valid_593619 != nil:
    section.add "X-Amz-Security-Token", valid_593619
  var valid_593620 = header.getOrDefault("X-Amz-Algorithm")
  valid_593620 = validateParameter(valid_593620, JString, required = false,
                                 default = nil)
  if valid_593620 != nil:
    section.add "X-Amz-Algorithm", valid_593620
  var valid_593621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-SignedHeaders", valid_593621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593622: Call_GetListSubscriptionsByTopic_593608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593622.validator(path, query, header, formData, body)
  let scheme = call_593622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593622.url(scheme.get, call_593622.host, call_593622.base,
                         call_593622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593622, url, valid)

proc call*(call_593623: Call_GetListSubscriptionsByTopic_593608; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  var query_593624 = newJObject()
  add(query_593624, "NextToken", newJString(NextToken))
  add(query_593624, "Action", newJString(Action))
  add(query_593624, "Version", newJString(Version))
  add(query_593624, "TopicArn", newJString(TopicArn))
  result = call_593623.call(nil, query_593624, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_593608(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_593609, base: "/",
    url: url_GetListSubscriptionsByTopic_593610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_593659 = ref object of OpenApiRestCall_592364
proc url_PostListTagsForResource_593661(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_593660(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593662 = query.getOrDefault("Action")
  valid_593662 = validateParameter(valid_593662, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_593662 != nil:
    section.add "Action", valid_593662
  var valid_593663 = query.getOrDefault("Version")
  valid_593663 = validateParameter(valid_593663, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593663 != nil:
    section.add "Version", valid_593663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593664 = header.getOrDefault("X-Amz-Signature")
  valid_593664 = validateParameter(valid_593664, JString, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "X-Amz-Signature", valid_593664
  var valid_593665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593665 = validateParameter(valid_593665, JString, required = false,
                                 default = nil)
  if valid_593665 != nil:
    section.add "X-Amz-Content-Sha256", valid_593665
  var valid_593666 = header.getOrDefault("X-Amz-Date")
  valid_593666 = validateParameter(valid_593666, JString, required = false,
                                 default = nil)
  if valid_593666 != nil:
    section.add "X-Amz-Date", valid_593666
  var valid_593667 = header.getOrDefault("X-Amz-Credential")
  valid_593667 = validateParameter(valid_593667, JString, required = false,
                                 default = nil)
  if valid_593667 != nil:
    section.add "X-Amz-Credential", valid_593667
  var valid_593668 = header.getOrDefault("X-Amz-Security-Token")
  valid_593668 = validateParameter(valid_593668, JString, required = false,
                                 default = nil)
  if valid_593668 != nil:
    section.add "X-Amz-Security-Token", valid_593668
  var valid_593669 = header.getOrDefault("X-Amz-Algorithm")
  valid_593669 = validateParameter(valid_593669, JString, required = false,
                                 default = nil)
  if valid_593669 != nil:
    section.add "X-Amz-Algorithm", valid_593669
  var valid_593670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593670 = validateParameter(valid_593670, JString, required = false,
                                 default = nil)
  if valid_593670 != nil:
    section.add "X-Amz-SignedHeaders", valid_593670
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_593671 = formData.getOrDefault("ResourceArn")
  valid_593671 = validateParameter(valid_593671, JString, required = true,
                                 default = nil)
  if valid_593671 != nil:
    section.add "ResourceArn", valid_593671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593672: Call_PostListTagsForResource_593659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_593672.validator(path, query, header, formData, body)
  let scheme = call_593672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593672.url(scheme.get, call_593672.host, call_593672.base,
                         call_593672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593672, url, valid)

proc call*(call_593673: Call_PostListTagsForResource_593659; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593674 = newJObject()
  var formData_593675 = newJObject()
  add(formData_593675, "ResourceArn", newJString(ResourceArn))
  add(query_593674, "Action", newJString(Action))
  add(query_593674, "Version", newJString(Version))
  result = call_593673.call(nil, query_593674, nil, formData_593675, nil)

var postListTagsForResource* = Call_PostListTagsForResource_593659(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_593660, base: "/",
    url: url_PostListTagsForResource_593661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_593643 = ref object of OpenApiRestCall_592364
proc url_GetListTagsForResource_593645(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_593644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_593646 = query.getOrDefault("ResourceArn")
  valid_593646 = validateParameter(valid_593646, JString, required = true,
                                 default = nil)
  if valid_593646 != nil:
    section.add "ResourceArn", valid_593646
  var valid_593647 = query.getOrDefault("Action")
  valid_593647 = validateParameter(valid_593647, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_593647 != nil:
    section.add "Action", valid_593647
  var valid_593648 = query.getOrDefault("Version")
  valid_593648 = validateParameter(valid_593648, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593648 != nil:
    section.add "Version", valid_593648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593649 = header.getOrDefault("X-Amz-Signature")
  valid_593649 = validateParameter(valid_593649, JString, required = false,
                                 default = nil)
  if valid_593649 != nil:
    section.add "X-Amz-Signature", valid_593649
  var valid_593650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593650 = validateParameter(valid_593650, JString, required = false,
                                 default = nil)
  if valid_593650 != nil:
    section.add "X-Amz-Content-Sha256", valid_593650
  var valid_593651 = header.getOrDefault("X-Amz-Date")
  valid_593651 = validateParameter(valid_593651, JString, required = false,
                                 default = nil)
  if valid_593651 != nil:
    section.add "X-Amz-Date", valid_593651
  var valid_593652 = header.getOrDefault("X-Amz-Credential")
  valid_593652 = validateParameter(valid_593652, JString, required = false,
                                 default = nil)
  if valid_593652 != nil:
    section.add "X-Amz-Credential", valid_593652
  var valid_593653 = header.getOrDefault("X-Amz-Security-Token")
  valid_593653 = validateParameter(valid_593653, JString, required = false,
                                 default = nil)
  if valid_593653 != nil:
    section.add "X-Amz-Security-Token", valid_593653
  var valid_593654 = header.getOrDefault("X-Amz-Algorithm")
  valid_593654 = validateParameter(valid_593654, JString, required = false,
                                 default = nil)
  if valid_593654 != nil:
    section.add "X-Amz-Algorithm", valid_593654
  var valid_593655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593655 = validateParameter(valid_593655, JString, required = false,
                                 default = nil)
  if valid_593655 != nil:
    section.add "X-Amz-SignedHeaders", valid_593655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593656: Call_GetListTagsForResource_593643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_593656.validator(path, query, header, formData, body)
  let scheme = call_593656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593656.url(scheme.get, call_593656.host, call_593656.base,
                         call_593656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593656, url, valid)

proc call*(call_593657: Call_GetListTagsForResource_593643; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593658 = newJObject()
  add(query_593658, "ResourceArn", newJString(ResourceArn))
  add(query_593658, "Action", newJString(Action))
  add(query_593658, "Version", newJString(Version))
  result = call_593657.call(nil, query_593658, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_593643(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_593644, base: "/",
    url: url_GetListTagsForResource_593645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_593692 = ref object of OpenApiRestCall_592364
proc url_PostListTopics_593694(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTopics_593693(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593695 = query.getOrDefault("Action")
  valid_593695 = validateParameter(valid_593695, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_593695 != nil:
    section.add "Action", valid_593695
  var valid_593696 = query.getOrDefault("Version")
  valid_593696 = validateParameter(valid_593696, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593696 != nil:
    section.add "Version", valid_593696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593697 = header.getOrDefault("X-Amz-Signature")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Signature", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Content-Sha256", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Date")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Date", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-Credential")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Credential", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-Security-Token")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-Security-Token", valid_593701
  var valid_593702 = header.getOrDefault("X-Amz-Algorithm")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "X-Amz-Algorithm", valid_593702
  var valid_593703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "X-Amz-SignedHeaders", valid_593703
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_593704 = formData.getOrDefault("NextToken")
  valid_593704 = validateParameter(valid_593704, JString, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "NextToken", valid_593704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593705: Call_PostListTopics_593692; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593705.validator(path, query, header, formData, body)
  let scheme = call_593705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593705.url(scheme.get, call_593705.host, call_593705.base,
                         call_593705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593705, url, valid)

proc call*(call_593706: Call_PostListTopics_593692; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593707 = newJObject()
  var formData_593708 = newJObject()
  add(formData_593708, "NextToken", newJString(NextToken))
  add(query_593707, "Action", newJString(Action))
  add(query_593707, "Version", newJString(Version))
  result = call_593706.call(nil, query_593707, nil, formData_593708, nil)

var postListTopics* = Call_PostListTopics_593692(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_593693,
    base: "/", url: url_PostListTopics_593694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_593676 = ref object of OpenApiRestCall_592364
proc url_GetListTopics_593678(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTopics_593677(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593679 = query.getOrDefault("NextToken")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "NextToken", valid_593679
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593680 = query.getOrDefault("Action")
  valid_593680 = validateParameter(valid_593680, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_593680 != nil:
    section.add "Action", valid_593680
  var valid_593681 = query.getOrDefault("Version")
  valid_593681 = validateParameter(valid_593681, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593681 != nil:
    section.add "Version", valid_593681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593682 = header.getOrDefault("X-Amz-Signature")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Signature", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Content-Sha256", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Date")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Date", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-Credential")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Credential", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-Security-Token")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-Security-Token", valid_593686
  var valid_593687 = header.getOrDefault("X-Amz-Algorithm")
  valid_593687 = validateParameter(valid_593687, JString, required = false,
                                 default = nil)
  if valid_593687 != nil:
    section.add "X-Amz-Algorithm", valid_593687
  var valid_593688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593688 = validateParameter(valid_593688, JString, required = false,
                                 default = nil)
  if valid_593688 != nil:
    section.add "X-Amz-SignedHeaders", valid_593688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593689: Call_GetListTopics_593676; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_593689.validator(path, query, header, formData, body)
  let scheme = call_593689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593689.url(scheme.get, call_593689.host, call_593689.base,
                         call_593689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593689, url, valid)

proc call*(call_593690: Call_GetListTopics_593676; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593691 = newJObject()
  add(query_593691, "NextToken", newJString(NextToken))
  add(query_593691, "Action", newJString(Action))
  add(query_593691, "Version", newJString(Version))
  result = call_593690.call(nil, query_593691, nil, nil, nil)

var getListTopics* = Call_GetListTopics_593676(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_593677,
    base: "/", url: url_GetListTopics_593678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_593725 = ref object of OpenApiRestCall_592364
proc url_PostOptInPhoneNumber_593727(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostOptInPhoneNumber_593726(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593728 = query.getOrDefault("Action")
  valid_593728 = validateParameter(valid_593728, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_593728 != nil:
    section.add "Action", valid_593728
  var valid_593729 = query.getOrDefault("Version")
  valid_593729 = validateParameter(valid_593729, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593729 != nil:
    section.add "Version", valid_593729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593730 = header.getOrDefault("X-Amz-Signature")
  valid_593730 = validateParameter(valid_593730, JString, required = false,
                                 default = nil)
  if valid_593730 != nil:
    section.add "X-Amz-Signature", valid_593730
  var valid_593731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593731 = validateParameter(valid_593731, JString, required = false,
                                 default = nil)
  if valid_593731 != nil:
    section.add "X-Amz-Content-Sha256", valid_593731
  var valid_593732 = header.getOrDefault("X-Amz-Date")
  valid_593732 = validateParameter(valid_593732, JString, required = false,
                                 default = nil)
  if valid_593732 != nil:
    section.add "X-Amz-Date", valid_593732
  var valid_593733 = header.getOrDefault("X-Amz-Credential")
  valid_593733 = validateParameter(valid_593733, JString, required = false,
                                 default = nil)
  if valid_593733 != nil:
    section.add "X-Amz-Credential", valid_593733
  var valid_593734 = header.getOrDefault("X-Amz-Security-Token")
  valid_593734 = validateParameter(valid_593734, JString, required = false,
                                 default = nil)
  if valid_593734 != nil:
    section.add "X-Amz-Security-Token", valid_593734
  var valid_593735 = header.getOrDefault("X-Amz-Algorithm")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Algorithm", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-SignedHeaders", valid_593736
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_593737 = formData.getOrDefault("phoneNumber")
  valid_593737 = validateParameter(valid_593737, JString, required = true,
                                 default = nil)
  if valid_593737 != nil:
    section.add "phoneNumber", valid_593737
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593738: Call_PostOptInPhoneNumber_593725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_593738.validator(path, query, header, formData, body)
  let scheme = call_593738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593738.url(scheme.get, call_593738.host, call_593738.base,
                         call_593738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593738, url, valid)

proc call*(call_593739: Call_PostOptInPhoneNumber_593725; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593740 = newJObject()
  var formData_593741 = newJObject()
  add(formData_593741, "phoneNumber", newJString(phoneNumber))
  add(query_593740, "Action", newJString(Action))
  add(query_593740, "Version", newJString(Version))
  result = call_593739.call(nil, query_593740, nil, formData_593741, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_593725(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_593726, base: "/",
    url: url_PostOptInPhoneNumber_593727, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_593709 = ref object of OpenApiRestCall_592364
proc url_GetOptInPhoneNumber_593711(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOptInPhoneNumber_593710(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_593712 = query.getOrDefault("phoneNumber")
  valid_593712 = validateParameter(valid_593712, JString, required = true,
                                 default = nil)
  if valid_593712 != nil:
    section.add "phoneNumber", valid_593712
  var valid_593713 = query.getOrDefault("Action")
  valid_593713 = validateParameter(valid_593713, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_593713 != nil:
    section.add "Action", valid_593713
  var valid_593714 = query.getOrDefault("Version")
  valid_593714 = validateParameter(valid_593714, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593714 != nil:
    section.add "Version", valid_593714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593715 = header.getOrDefault("X-Amz-Signature")
  valid_593715 = validateParameter(valid_593715, JString, required = false,
                                 default = nil)
  if valid_593715 != nil:
    section.add "X-Amz-Signature", valid_593715
  var valid_593716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "X-Amz-Content-Sha256", valid_593716
  var valid_593717 = header.getOrDefault("X-Amz-Date")
  valid_593717 = validateParameter(valid_593717, JString, required = false,
                                 default = nil)
  if valid_593717 != nil:
    section.add "X-Amz-Date", valid_593717
  var valid_593718 = header.getOrDefault("X-Amz-Credential")
  valid_593718 = validateParameter(valid_593718, JString, required = false,
                                 default = nil)
  if valid_593718 != nil:
    section.add "X-Amz-Credential", valid_593718
  var valid_593719 = header.getOrDefault("X-Amz-Security-Token")
  valid_593719 = validateParameter(valid_593719, JString, required = false,
                                 default = nil)
  if valid_593719 != nil:
    section.add "X-Amz-Security-Token", valid_593719
  var valid_593720 = header.getOrDefault("X-Amz-Algorithm")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "X-Amz-Algorithm", valid_593720
  var valid_593721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-SignedHeaders", valid_593721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593722: Call_GetOptInPhoneNumber_593709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_593722.validator(path, query, header, formData, body)
  let scheme = call_593722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593722.url(scheme.get, call_593722.host, call_593722.base,
                         call_593722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593722, url, valid)

proc call*(call_593723: Call_GetOptInPhoneNumber_593709; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593724 = newJObject()
  add(query_593724, "phoneNumber", newJString(phoneNumber))
  add(query_593724, "Action", newJString(Action))
  add(query_593724, "Version", newJString(Version))
  result = call_593723.call(nil, query_593724, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_593709(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_593710, base: "/",
    url: url_GetOptInPhoneNumber_593711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_593769 = ref object of OpenApiRestCall_592364
proc url_PostPublish_593771(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPublish_593770(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593772 = query.getOrDefault("Action")
  valid_593772 = validateParameter(valid_593772, JString, required = true,
                                 default = newJString("Publish"))
  if valid_593772 != nil:
    section.add "Action", valid_593772
  var valid_593773 = query.getOrDefault("Version")
  valid_593773 = validateParameter(valid_593773, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593773 != nil:
    section.add "Version", valid_593773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593774 = header.getOrDefault("X-Amz-Signature")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Signature", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Content-Sha256", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Date")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Date", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-Credential")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-Credential", valid_593777
  var valid_593778 = header.getOrDefault("X-Amz-Security-Token")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "X-Amz-Security-Token", valid_593778
  var valid_593779 = header.getOrDefault("X-Amz-Algorithm")
  valid_593779 = validateParameter(valid_593779, JString, required = false,
                                 default = nil)
  if valid_593779 != nil:
    section.add "X-Amz-Algorithm", valid_593779
  var valid_593780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593780 = validateParameter(valid_593780, JString, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "X-Amz-SignedHeaders", valid_593780
  result.add "header", section
  ## parameters in `formData` object:
  ##   MessageAttributes.1.key: JString
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.2.value: JString
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.0.key: JString
  ##   MessageAttributes.2.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.1.value: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  section = newJObject()
  var valid_593781 = formData.getOrDefault("MessageAttributes.1.key")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "MessageAttributes.1.key", valid_593781
  var valid_593782 = formData.getOrDefault("PhoneNumber")
  valid_593782 = validateParameter(valid_593782, JString, required = false,
                                 default = nil)
  if valid_593782 != nil:
    section.add "PhoneNumber", valid_593782
  var valid_593783 = formData.getOrDefault("MessageAttributes.2.value")
  valid_593783 = validateParameter(valid_593783, JString, required = false,
                                 default = nil)
  if valid_593783 != nil:
    section.add "MessageAttributes.2.value", valid_593783
  var valid_593784 = formData.getOrDefault("Subject")
  valid_593784 = validateParameter(valid_593784, JString, required = false,
                                 default = nil)
  if valid_593784 != nil:
    section.add "Subject", valid_593784
  var valid_593785 = formData.getOrDefault("MessageAttributes.0.value")
  valid_593785 = validateParameter(valid_593785, JString, required = false,
                                 default = nil)
  if valid_593785 != nil:
    section.add "MessageAttributes.0.value", valid_593785
  var valid_593786 = formData.getOrDefault("MessageAttributes.0.key")
  valid_593786 = validateParameter(valid_593786, JString, required = false,
                                 default = nil)
  if valid_593786 != nil:
    section.add "MessageAttributes.0.key", valid_593786
  var valid_593787 = formData.getOrDefault("MessageAttributes.2.key")
  valid_593787 = validateParameter(valid_593787, JString, required = false,
                                 default = nil)
  if valid_593787 != nil:
    section.add "MessageAttributes.2.key", valid_593787
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_593788 = formData.getOrDefault("Message")
  valid_593788 = validateParameter(valid_593788, JString, required = true,
                                 default = nil)
  if valid_593788 != nil:
    section.add "Message", valid_593788
  var valid_593789 = formData.getOrDefault("TopicArn")
  valid_593789 = validateParameter(valid_593789, JString, required = false,
                                 default = nil)
  if valid_593789 != nil:
    section.add "TopicArn", valid_593789
  var valid_593790 = formData.getOrDefault("MessageStructure")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "MessageStructure", valid_593790
  var valid_593791 = formData.getOrDefault("MessageAttributes.1.value")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "MessageAttributes.1.value", valid_593791
  var valid_593792 = formData.getOrDefault("TargetArn")
  valid_593792 = validateParameter(valid_593792, JString, required = false,
                                 default = nil)
  if valid_593792 != nil:
    section.add "TargetArn", valid_593792
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593793: Call_PostPublish_593769; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_593793.validator(path, query, header, formData, body)
  let scheme = call_593793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593793.url(scheme.get, call_593793.host, call_593793.base,
                         call_593793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593793, url, valid)

proc call*(call_593794: Call_PostPublish_593769; Message: string;
          MessageAttributes1Key: string = ""; PhoneNumber: string = "";
          MessageAttributes2Value: string = ""; Subject: string = "";
          MessageAttributes0Value: string = ""; MessageAttributes0Key: string = "";
          MessageAttributes2Key: string = ""; TopicArn: string = "";
          Action: string = "Publish"; MessageStructure: string = "";
          MessageAttributes1Value: string = ""; TargetArn: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   MessageAttributes1Key: string
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes2Value: string
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes0Key: string
  ##   MessageAttributes2Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes1Value: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_593795 = newJObject()
  var formData_593796 = newJObject()
  add(formData_593796, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_593796, "PhoneNumber", newJString(PhoneNumber))
  add(formData_593796, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(formData_593796, "Subject", newJString(Subject))
  add(formData_593796, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_593796, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_593796, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(formData_593796, "Message", newJString(Message))
  add(formData_593796, "TopicArn", newJString(TopicArn))
  add(query_593795, "Action", newJString(Action))
  add(formData_593796, "MessageStructure", newJString(MessageStructure))
  add(formData_593796, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_593796, "TargetArn", newJString(TargetArn))
  add(query_593795, "Version", newJString(Version))
  result = call_593794.call(nil, query_593795, nil, formData_593796, nil)

var postPublish* = Call_PostPublish_593769(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_593770,
                                        base: "/", url: url_PostPublish_593771,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_593742 = ref object of OpenApiRestCall_592364
proc url_GetPublish_593744(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPublish_593743(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.2.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageAttributes.2.value: JString
  ##   Action: JString (required)
  ##   MessageAttributes.1.key: JString
  ##   MessageAttributes.0.key: JString
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.1.value: JString
  ##   Version: JString (required)
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  section = newJObject()
  var valid_593745 = query.getOrDefault("PhoneNumber")
  valid_593745 = validateParameter(valid_593745, JString, required = false,
                                 default = nil)
  if valid_593745 != nil:
    section.add "PhoneNumber", valid_593745
  var valid_593746 = query.getOrDefault("MessageStructure")
  valid_593746 = validateParameter(valid_593746, JString, required = false,
                                 default = nil)
  if valid_593746 != nil:
    section.add "MessageStructure", valid_593746
  var valid_593747 = query.getOrDefault("MessageAttributes.0.value")
  valid_593747 = validateParameter(valid_593747, JString, required = false,
                                 default = nil)
  if valid_593747 != nil:
    section.add "MessageAttributes.0.value", valid_593747
  var valid_593748 = query.getOrDefault("MessageAttributes.2.key")
  valid_593748 = validateParameter(valid_593748, JString, required = false,
                                 default = nil)
  if valid_593748 != nil:
    section.add "MessageAttributes.2.key", valid_593748
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_593749 = query.getOrDefault("Message")
  valid_593749 = validateParameter(valid_593749, JString, required = true,
                                 default = nil)
  if valid_593749 != nil:
    section.add "Message", valid_593749
  var valid_593750 = query.getOrDefault("MessageAttributes.2.value")
  valid_593750 = validateParameter(valid_593750, JString, required = false,
                                 default = nil)
  if valid_593750 != nil:
    section.add "MessageAttributes.2.value", valid_593750
  var valid_593751 = query.getOrDefault("Action")
  valid_593751 = validateParameter(valid_593751, JString, required = true,
                                 default = newJString("Publish"))
  if valid_593751 != nil:
    section.add "Action", valid_593751
  var valid_593752 = query.getOrDefault("MessageAttributes.1.key")
  valid_593752 = validateParameter(valid_593752, JString, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "MessageAttributes.1.key", valid_593752
  var valid_593753 = query.getOrDefault("MessageAttributes.0.key")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "MessageAttributes.0.key", valid_593753
  var valid_593754 = query.getOrDefault("Subject")
  valid_593754 = validateParameter(valid_593754, JString, required = false,
                                 default = nil)
  if valid_593754 != nil:
    section.add "Subject", valid_593754
  var valid_593755 = query.getOrDefault("MessageAttributes.1.value")
  valid_593755 = validateParameter(valid_593755, JString, required = false,
                                 default = nil)
  if valid_593755 != nil:
    section.add "MessageAttributes.1.value", valid_593755
  var valid_593756 = query.getOrDefault("Version")
  valid_593756 = validateParameter(valid_593756, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593756 != nil:
    section.add "Version", valid_593756
  var valid_593757 = query.getOrDefault("TargetArn")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "TargetArn", valid_593757
  var valid_593758 = query.getOrDefault("TopicArn")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "TopicArn", valid_593758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593759 = header.getOrDefault("X-Amz-Signature")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Signature", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Content-Sha256", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Date")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Date", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-Credential")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-Credential", valid_593762
  var valid_593763 = header.getOrDefault("X-Amz-Security-Token")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-Security-Token", valid_593763
  var valid_593764 = header.getOrDefault("X-Amz-Algorithm")
  valid_593764 = validateParameter(valid_593764, JString, required = false,
                                 default = nil)
  if valid_593764 != nil:
    section.add "X-Amz-Algorithm", valid_593764
  var valid_593765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593765 = validateParameter(valid_593765, JString, required = false,
                                 default = nil)
  if valid_593765 != nil:
    section.add "X-Amz-SignedHeaders", valid_593765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593766: Call_GetPublish_593742; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_593766.validator(path, query, header, formData, body)
  let scheme = call_593766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593766.url(scheme.get, call_593766.host, call_593766.base,
                         call_593766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593766, url, valid)

proc call*(call_593767: Call_GetPublish_593742; Message: string;
          PhoneNumber: string = ""; MessageStructure: string = "";
          MessageAttributes0Value: string = ""; MessageAttributes2Key: string = "";
          MessageAttributes2Value: string = ""; Action: string = "Publish";
          MessageAttributes1Key: string = ""; MessageAttributes0Key: string = "";
          Subject: string = ""; MessageAttributes1Value: string = "";
          Version: string = "2010-03-31"; TargetArn: string = ""; TopicArn: string = ""): Recallable =
  ## getPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes2Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageAttributes2Value: string
  ##   Action: string (required)
  ##   MessageAttributes1Key: string
  ##   MessageAttributes0Key: string
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes1Value: string
  ##   Version: string (required)
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  var query_593768 = newJObject()
  add(query_593768, "PhoneNumber", newJString(PhoneNumber))
  add(query_593768, "MessageStructure", newJString(MessageStructure))
  add(query_593768, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_593768, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_593768, "Message", newJString(Message))
  add(query_593768, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_593768, "Action", newJString(Action))
  add(query_593768, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_593768, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_593768, "Subject", newJString(Subject))
  add(query_593768, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_593768, "Version", newJString(Version))
  add(query_593768, "TargetArn", newJString(TargetArn))
  add(query_593768, "TopicArn", newJString(TopicArn))
  result = call_593767.call(nil, query_593768, nil, nil, nil)

var getPublish* = Call_GetPublish_593742(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_593743,
                                      base: "/", url: url_GetPublish_593744,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_593814 = ref object of OpenApiRestCall_592364
proc url_PostRemovePermission_593816(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemovePermission_593815(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593817 = query.getOrDefault("Action")
  valid_593817 = validateParameter(valid_593817, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_593817 != nil:
    section.add "Action", valid_593817
  var valid_593818 = query.getOrDefault("Version")
  valid_593818 = validateParameter(valid_593818, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593818 != nil:
    section.add "Version", valid_593818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593819 = header.getOrDefault("X-Amz-Signature")
  valid_593819 = validateParameter(valid_593819, JString, required = false,
                                 default = nil)
  if valid_593819 != nil:
    section.add "X-Amz-Signature", valid_593819
  var valid_593820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "X-Amz-Content-Sha256", valid_593820
  var valid_593821 = header.getOrDefault("X-Amz-Date")
  valid_593821 = validateParameter(valid_593821, JString, required = false,
                                 default = nil)
  if valid_593821 != nil:
    section.add "X-Amz-Date", valid_593821
  var valid_593822 = header.getOrDefault("X-Amz-Credential")
  valid_593822 = validateParameter(valid_593822, JString, required = false,
                                 default = nil)
  if valid_593822 != nil:
    section.add "X-Amz-Credential", valid_593822
  var valid_593823 = header.getOrDefault("X-Amz-Security-Token")
  valid_593823 = validateParameter(valid_593823, JString, required = false,
                                 default = nil)
  if valid_593823 != nil:
    section.add "X-Amz-Security-Token", valid_593823
  var valid_593824 = header.getOrDefault("X-Amz-Algorithm")
  valid_593824 = validateParameter(valid_593824, JString, required = false,
                                 default = nil)
  if valid_593824 != nil:
    section.add "X-Amz-Algorithm", valid_593824
  var valid_593825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593825 = validateParameter(valid_593825, JString, required = false,
                                 default = nil)
  if valid_593825 != nil:
    section.add "X-Amz-SignedHeaders", valid_593825
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_593826 = formData.getOrDefault("TopicArn")
  valid_593826 = validateParameter(valid_593826, JString, required = true,
                                 default = nil)
  if valid_593826 != nil:
    section.add "TopicArn", valid_593826
  var valid_593827 = formData.getOrDefault("Label")
  valid_593827 = validateParameter(valid_593827, JString, required = true,
                                 default = nil)
  if valid_593827 != nil:
    section.add "Label", valid_593827
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593828: Call_PostRemovePermission_593814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_593828.validator(path, query, header, formData, body)
  let scheme = call_593828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593828.url(scheme.get, call_593828.host, call_593828.base,
                         call_593828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593828, url, valid)

proc call*(call_593829: Call_PostRemovePermission_593814; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## postRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  ##   Version: string (required)
  var query_593830 = newJObject()
  var formData_593831 = newJObject()
  add(formData_593831, "TopicArn", newJString(TopicArn))
  add(query_593830, "Action", newJString(Action))
  add(formData_593831, "Label", newJString(Label))
  add(query_593830, "Version", newJString(Version))
  result = call_593829.call(nil, query_593830, nil, formData_593831, nil)

var postRemovePermission* = Call_PostRemovePermission_593814(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_593815, base: "/",
    url: url_PostRemovePermission_593816, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_593797 = ref object of OpenApiRestCall_592364
proc url_GetRemovePermission_593799(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemovePermission_593798(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TopicArn` field"
  var valid_593800 = query.getOrDefault("TopicArn")
  valid_593800 = validateParameter(valid_593800, JString, required = true,
                                 default = nil)
  if valid_593800 != nil:
    section.add "TopicArn", valid_593800
  var valid_593801 = query.getOrDefault("Action")
  valid_593801 = validateParameter(valid_593801, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_593801 != nil:
    section.add "Action", valid_593801
  var valid_593802 = query.getOrDefault("Version")
  valid_593802 = validateParameter(valid_593802, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593802 != nil:
    section.add "Version", valid_593802
  var valid_593803 = query.getOrDefault("Label")
  valid_593803 = validateParameter(valid_593803, JString, required = true,
                                 default = nil)
  if valid_593803 != nil:
    section.add "Label", valid_593803
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593804 = header.getOrDefault("X-Amz-Signature")
  valid_593804 = validateParameter(valid_593804, JString, required = false,
                                 default = nil)
  if valid_593804 != nil:
    section.add "X-Amz-Signature", valid_593804
  var valid_593805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593805 = validateParameter(valid_593805, JString, required = false,
                                 default = nil)
  if valid_593805 != nil:
    section.add "X-Amz-Content-Sha256", valid_593805
  var valid_593806 = header.getOrDefault("X-Amz-Date")
  valid_593806 = validateParameter(valid_593806, JString, required = false,
                                 default = nil)
  if valid_593806 != nil:
    section.add "X-Amz-Date", valid_593806
  var valid_593807 = header.getOrDefault("X-Amz-Credential")
  valid_593807 = validateParameter(valid_593807, JString, required = false,
                                 default = nil)
  if valid_593807 != nil:
    section.add "X-Amz-Credential", valid_593807
  var valid_593808 = header.getOrDefault("X-Amz-Security-Token")
  valid_593808 = validateParameter(valid_593808, JString, required = false,
                                 default = nil)
  if valid_593808 != nil:
    section.add "X-Amz-Security-Token", valid_593808
  var valid_593809 = header.getOrDefault("X-Amz-Algorithm")
  valid_593809 = validateParameter(valid_593809, JString, required = false,
                                 default = nil)
  if valid_593809 != nil:
    section.add "X-Amz-Algorithm", valid_593809
  var valid_593810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-SignedHeaders", valid_593810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593811: Call_GetRemovePermission_593797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_593811.validator(path, query, header, formData, body)
  let scheme = call_593811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593811.url(scheme.get, call_593811.host, call_593811.base,
                         call_593811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593811, url, valid)

proc call*(call_593812: Call_GetRemovePermission_593797; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## getRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  var query_593813 = newJObject()
  add(query_593813, "TopicArn", newJString(TopicArn))
  add(query_593813, "Action", newJString(Action))
  add(query_593813, "Version", newJString(Version))
  add(query_593813, "Label", newJString(Label))
  result = call_593812.call(nil, query_593813, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_593797(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_593798, base: "/",
    url: url_GetRemovePermission_593799, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_593854 = ref object of OpenApiRestCall_592364
proc url_PostSetEndpointAttributes_593856(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetEndpointAttributes_593855(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593857 = query.getOrDefault("Action")
  valid_593857 = validateParameter(valid_593857, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_593857 != nil:
    section.add "Action", valid_593857
  var valid_593858 = query.getOrDefault("Version")
  valid_593858 = validateParameter(valid_593858, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593858 != nil:
    section.add "Version", valid_593858
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593859 = header.getOrDefault("X-Amz-Signature")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Signature", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Content-Sha256", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-Date")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-Date", valid_593861
  var valid_593862 = header.getOrDefault("X-Amz-Credential")
  valid_593862 = validateParameter(valid_593862, JString, required = false,
                                 default = nil)
  if valid_593862 != nil:
    section.add "X-Amz-Credential", valid_593862
  var valid_593863 = header.getOrDefault("X-Amz-Security-Token")
  valid_593863 = validateParameter(valid_593863, JString, required = false,
                                 default = nil)
  if valid_593863 != nil:
    section.add "X-Amz-Security-Token", valid_593863
  var valid_593864 = header.getOrDefault("X-Amz-Algorithm")
  valid_593864 = validateParameter(valid_593864, JString, required = false,
                                 default = nil)
  if valid_593864 != nil:
    section.add "X-Amz-Algorithm", valid_593864
  var valid_593865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "X-Amz-SignedHeaders", valid_593865
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_593866 = formData.getOrDefault("Attributes.0.key")
  valid_593866 = validateParameter(valid_593866, JString, required = false,
                                 default = nil)
  if valid_593866 != nil:
    section.add "Attributes.0.key", valid_593866
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_593867 = formData.getOrDefault("EndpointArn")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = nil)
  if valid_593867 != nil:
    section.add "EndpointArn", valid_593867
  var valid_593868 = formData.getOrDefault("Attributes.2.value")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "Attributes.2.value", valid_593868
  var valid_593869 = formData.getOrDefault("Attributes.2.key")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "Attributes.2.key", valid_593869
  var valid_593870 = formData.getOrDefault("Attributes.0.value")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "Attributes.0.value", valid_593870
  var valid_593871 = formData.getOrDefault("Attributes.1.key")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "Attributes.1.key", valid_593871
  var valid_593872 = formData.getOrDefault("Attributes.1.value")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "Attributes.1.value", valid_593872
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593873: Call_PostSetEndpointAttributes_593854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593873.validator(path, query, header, formData, body)
  let scheme = call_593873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593873.url(scheme.get, call_593873.host, call_593873.base,
                         call_593873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593873, url, valid)

proc call*(call_593874: Call_PostSetEndpointAttributes_593854; EndpointArn: string;
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Attributes0Value: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes0Key: string
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_593875 = newJObject()
  var formData_593876 = newJObject()
  add(formData_593876, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_593876, "EndpointArn", newJString(EndpointArn))
  add(formData_593876, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_593876, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_593876, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_593876, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593875, "Action", newJString(Action))
  add(query_593875, "Version", newJString(Version))
  add(formData_593876, "Attributes.1.value", newJString(Attributes1Value))
  result = call_593874.call(nil, query_593875, nil, formData_593876, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_593854(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_593855, base: "/",
    url: url_PostSetEndpointAttributes_593856,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_593832 = ref object of OpenApiRestCall_592364
proc url_GetSetEndpointAttributes_593834(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetEndpointAttributes_593833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_593835 = query.getOrDefault("Attributes.1.key")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "Attributes.1.key", valid_593835
  var valid_593836 = query.getOrDefault("Attributes.0.value")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "Attributes.0.value", valid_593836
  var valid_593837 = query.getOrDefault("Attributes.0.key")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "Attributes.0.key", valid_593837
  var valid_593838 = query.getOrDefault("Attributes.2.value")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "Attributes.2.value", valid_593838
  var valid_593839 = query.getOrDefault("Attributes.1.value")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "Attributes.1.value", valid_593839
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593840 = query.getOrDefault("Action")
  valid_593840 = validateParameter(valid_593840, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_593840 != nil:
    section.add "Action", valid_593840
  var valid_593841 = query.getOrDefault("EndpointArn")
  valid_593841 = validateParameter(valid_593841, JString, required = true,
                                 default = nil)
  if valid_593841 != nil:
    section.add "EndpointArn", valid_593841
  var valid_593842 = query.getOrDefault("Version")
  valid_593842 = validateParameter(valid_593842, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593842 != nil:
    section.add "Version", valid_593842
  var valid_593843 = query.getOrDefault("Attributes.2.key")
  valid_593843 = validateParameter(valid_593843, JString, required = false,
                                 default = nil)
  if valid_593843 != nil:
    section.add "Attributes.2.key", valid_593843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593844 = header.getOrDefault("X-Amz-Signature")
  valid_593844 = validateParameter(valid_593844, JString, required = false,
                                 default = nil)
  if valid_593844 != nil:
    section.add "X-Amz-Signature", valid_593844
  var valid_593845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593845 = validateParameter(valid_593845, JString, required = false,
                                 default = nil)
  if valid_593845 != nil:
    section.add "X-Amz-Content-Sha256", valid_593845
  var valid_593846 = header.getOrDefault("X-Amz-Date")
  valid_593846 = validateParameter(valid_593846, JString, required = false,
                                 default = nil)
  if valid_593846 != nil:
    section.add "X-Amz-Date", valid_593846
  var valid_593847 = header.getOrDefault("X-Amz-Credential")
  valid_593847 = validateParameter(valid_593847, JString, required = false,
                                 default = nil)
  if valid_593847 != nil:
    section.add "X-Amz-Credential", valid_593847
  var valid_593848 = header.getOrDefault("X-Amz-Security-Token")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Security-Token", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Algorithm")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Algorithm", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-SignedHeaders", valid_593850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593851: Call_GetSetEndpointAttributes_593832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_593851.validator(path, query, header, formData, body)
  let scheme = call_593851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593851.url(scheme.get, call_593851.host, call_593851.base,
                         call_593851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593851, url, valid)

proc call*(call_593852: Call_GetSetEndpointAttributes_593832; EndpointArn: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = ""; Action: string = "SetEndpointAttributes";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_593853 = newJObject()
  add(query_593853, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593853, "Attributes.0.value", newJString(Attributes0Value))
  add(query_593853, "Attributes.0.key", newJString(Attributes0Key))
  add(query_593853, "Attributes.2.value", newJString(Attributes2Value))
  add(query_593853, "Attributes.1.value", newJString(Attributes1Value))
  add(query_593853, "Action", newJString(Action))
  add(query_593853, "EndpointArn", newJString(EndpointArn))
  add(query_593853, "Version", newJString(Version))
  add(query_593853, "Attributes.2.key", newJString(Attributes2Key))
  result = call_593852.call(nil, query_593853, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_593832(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_593833, base: "/",
    url: url_GetSetEndpointAttributes_593834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_593899 = ref object of OpenApiRestCall_592364
proc url_PostSetPlatformApplicationAttributes_593901(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_593900(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593902 = query.getOrDefault("Action")
  valid_593902 = validateParameter(valid_593902, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_593902 != nil:
    section.add "Action", valid_593902
  var valid_593903 = query.getOrDefault("Version")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593903 != nil:
    section.add "Version", valid_593903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593904 = header.getOrDefault("X-Amz-Signature")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Signature", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Content-Sha256", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Date")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Date", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Credential")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Credential", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Security-Token")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Security-Token", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Algorithm")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Algorithm", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-SignedHeaders", valid_593910
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593911 = formData.getOrDefault("PlatformApplicationArn")
  valid_593911 = validateParameter(valid_593911, JString, required = true,
                                 default = nil)
  if valid_593911 != nil:
    section.add "PlatformApplicationArn", valid_593911
  var valid_593912 = formData.getOrDefault("Attributes.0.key")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "Attributes.0.key", valid_593912
  var valid_593913 = formData.getOrDefault("Attributes.2.value")
  valid_593913 = validateParameter(valid_593913, JString, required = false,
                                 default = nil)
  if valid_593913 != nil:
    section.add "Attributes.2.value", valid_593913
  var valid_593914 = formData.getOrDefault("Attributes.2.key")
  valid_593914 = validateParameter(valid_593914, JString, required = false,
                                 default = nil)
  if valid_593914 != nil:
    section.add "Attributes.2.key", valid_593914
  var valid_593915 = formData.getOrDefault("Attributes.0.value")
  valid_593915 = validateParameter(valid_593915, JString, required = false,
                                 default = nil)
  if valid_593915 != nil:
    section.add "Attributes.0.value", valid_593915
  var valid_593916 = formData.getOrDefault("Attributes.1.key")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "Attributes.1.key", valid_593916
  var valid_593917 = formData.getOrDefault("Attributes.1.value")
  valid_593917 = validateParameter(valid_593917, JString, required = false,
                                 default = nil)
  if valid_593917 != nil:
    section.add "Attributes.1.value", valid_593917
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593918: Call_PostSetPlatformApplicationAttributes_593899;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_593918.validator(path, query, header, formData, body)
  let scheme = call_593918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593918.url(scheme.get, call_593918.host, call_593918.base,
                         call_593918.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593918, url, valid)

proc call*(call_593919: Call_PostSetPlatformApplicationAttributes_593899;
          PlatformApplicationArn: string; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_593920 = newJObject()
  var formData_593921 = newJObject()
  add(formData_593921, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_593921, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_593921, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_593921, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_593921, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_593921, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593920, "Action", newJString(Action))
  add(query_593920, "Version", newJString(Version))
  add(formData_593921, "Attributes.1.value", newJString(Attributes1Value))
  result = call_593919.call(nil, query_593920, nil, formData_593921, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_593899(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_593900, base: "/",
    url: url_PostSetPlatformApplicationAttributes_593901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_593877 = ref object of OpenApiRestCall_592364
proc url_GetSetPlatformApplicationAttributes_593879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetPlatformApplicationAttributes_593878(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_593880 = query.getOrDefault("Attributes.1.key")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "Attributes.1.key", valid_593880
  var valid_593881 = query.getOrDefault("Attributes.0.value")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "Attributes.0.value", valid_593881
  var valid_593882 = query.getOrDefault("Attributes.0.key")
  valid_593882 = validateParameter(valid_593882, JString, required = false,
                                 default = nil)
  if valid_593882 != nil:
    section.add "Attributes.0.key", valid_593882
  var valid_593883 = query.getOrDefault("Attributes.2.value")
  valid_593883 = validateParameter(valid_593883, JString, required = false,
                                 default = nil)
  if valid_593883 != nil:
    section.add "Attributes.2.value", valid_593883
  var valid_593884 = query.getOrDefault("Attributes.1.value")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "Attributes.1.value", valid_593884
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_593885 = query.getOrDefault("PlatformApplicationArn")
  valid_593885 = validateParameter(valid_593885, JString, required = true,
                                 default = nil)
  if valid_593885 != nil:
    section.add "PlatformApplicationArn", valid_593885
  var valid_593886 = query.getOrDefault("Action")
  valid_593886 = validateParameter(valid_593886, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_593886 != nil:
    section.add "Action", valid_593886
  var valid_593887 = query.getOrDefault("Version")
  valid_593887 = validateParameter(valid_593887, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593887 != nil:
    section.add "Version", valid_593887
  var valid_593888 = query.getOrDefault("Attributes.2.key")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "Attributes.2.key", valid_593888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593889 = header.getOrDefault("X-Amz-Signature")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Signature", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-Content-Sha256", valid_593890
  var valid_593891 = header.getOrDefault("X-Amz-Date")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "X-Amz-Date", valid_593891
  var valid_593892 = header.getOrDefault("X-Amz-Credential")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Credential", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Security-Token")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Security-Token", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Algorithm")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Algorithm", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-SignedHeaders", valid_593895
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593896: Call_GetSetPlatformApplicationAttributes_593877;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_593896.validator(path, query, header, formData, body)
  let scheme = call_593896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593896.url(scheme.get, call_593896.host, call_593896.base,
                         call_593896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593896, url, valid)

proc call*(call_593897: Call_GetSetPlatformApplicationAttributes_593877;
          PlatformApplicationArn: string; Attributes1Key: string = "";
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_593898 = newJObject()
  add(query_593898, "Attributes.1.key", newJString(Attributes1Key))
  add(query_593898, "Attributes.0.value", newJString(Attributes0Value))
  add(query_593898, "Attributes.0.key", newJString(Attributes0Key))
  add(query_593898, "Attributes.2.value", newJString(Attributes2Value))
  add(query_593898, "Attributes.1.value", newJString(Attributes1Value))
  add(query_593898, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_593898, "Action", newJString(Action))
  add(query_593898, "Version", newJString(Version))
  add(query_593898, "Attributes.2.key", newJString(Attributes2Key))
  result = call_593897.call(nil, query_593898, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_593877(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_593878, base: "/",
    url: url_GetSetPlatformApplicationAttributes_593879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_593943 = ref object of OpenApiRestCall_592364
proc url_PostSetSMSAttributes_593945(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSMSAttributes_593944(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593946 = query.getOrDefault("Action")
  valid_593946 = validateParameter(valid_593946, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_593946 != nil:
    section.add "Action", valid_593946
  var valid_593947 = query.getOrDefault("Version")
  valid_593947 = validateParameter(valid_593947, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593947 != nil:
    section.add "Version", valid_593947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593948 = header.getOrDefault("X-Amz-Signature")
  valid_593948 = validateParameter(valid_593948, JString, required = false,
                                 default = nil)
  if valid_593948 != nil:
    section.add "X-Amz-Signature", valid_593948
  var valid_593949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593949 = validateParameter(valid_593949, JString, required = false,
                                 default = nil)
  if valid_593949 != nil:
    section.add "X-Amz-Content-Sha256", valid_593949
  var valid_593950 = header.getOrDefault("X-Amz-Date")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "X-Amz-Date", valid_593950
  var valid_593951 = header.getOrDefault("X-Amz-Credential")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = nil)
  if valid_593951 != nil:
    section.add "X-Amz-Credential", valid_593951
  var valid_593952 = header.getOrDefault("X-Amz-Security-Token")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "X-Amz-Security-Token", valid_593952
  var valid_593953 = header.getOrDefault("X-Amz-Algorithm")
  valid_593953 = validateParameter(valid_593953, JString, required = false,
                                 default = nil)
  if valid_593953 != nil:
    section.add "X-Amz-Algorithm", valid_593953
  var valid_593954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "X-Amz-SignedHeaders", valid_593954
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.1.key: JString
  ##   attributes.1.value: JString
  ##   attributes.2.key: JString
  ##   attributes.0.value: JString
  ##   attributes.0.key: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_593955 = formData.getOrDefault("attributes.1.key")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "attributes.1.key", valid_593955
  var valid_593956 = formData.getOrDefault("attributes.1.value")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "attributes.1.value", valid_593956
  var valid_593957 = formData.getOrDefault("attributes.2.key")
  valid_593957 = validateParameter(valid_593957, JString, required = false,
                                 default = nil)
  if valid_593957 != nil:
    section.add "attributes.2.key", valid_593957
  var valid_593958 = formData.getOrDefault("attributes.0.value")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "attributes.0.value", valid_593958
  var valid_593959 = formData.getOrDefault("attributes.0.key")
  valid_593959 = validateParameter(valid_593959, JString, required = false,
                                 default = nil)
  if valid_593959 != nil:
    section.add "attributes.0.key", valid_593959
  var valid_593960 = formData.getOrDefault("attributes.2.value")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "attributes.2.value", valid_593960
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593961: Call_PostSetSMSAttributes_593943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_593961.validator(path, query, header, formData, body)
  let scheme = call_593961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593961.url(scheme.get, call_593961.host, call_593961.base,
                         call_593961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593961, url, valid)

proc call*(call_593962: Call_PostSetSMSAttributes_593943;
          attributes1Key: string = ""; attributes1Value: string = "";
          attributes2Key: string = ""; attributes0Value: string = "";
          Action: string = "SetSMSAttributes"; Version: string = "2010-03-31";
          attributes0Key: string = ""; attributes2Value: string = ""): Recallable =
  ## postSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes1Key: string
  ##   attributes1Value: string
  ##   attributes2Key: string
  ##   attributes0Value: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   attributes0Key: string
  ##   attributes2Value: string
  var query_593963 = newJObject()
  var formData_593964 = newJObject()
  add(formData_593964, "attributes.1.key", newJString(attributes1Key))
  add(formData_593964, "attributes.1.value", newJString(attributes1Value))
  add(formData_593964, "attributes.2.key", newJString(attributes2Key))
  add(formData_593964, "attributes.0.value", newJString(attributes0Value))
  add(query_593963, "Action", newJString(Action))
  add(query_593963, "Version", newJString(Version))
  add(formData_593964, "attributes.0.key", newJString(attributes0Key))
  add(formData_593964, "attributes.2.value", newJString(attributes2Value))
  result = call_593962.call(nil, query_593963, nil, formData_593964, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_593943(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_593944, base: "/",
    url: url_PostSetSMSAttributes_593945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_593922 = ref object of OpenApiRestCall_592364
proc url_GetSetSMSAttributes_593924(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSMSAttributes_593923(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes.2.key: JString
  ##   attributes.0.key: JString
  ##   Action: JString (required)
  ##   attributes.1.key: JString
  ##   attributes.0.value: JString
  ##   Version: JString (required)
  ##   attributes.1.value: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_593925 = query.getOrDefault("attributes.2.key")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "attributes.2.key", valid_593925
  var valid_593926 = query.getOrDefault("attributes.0.key")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "attributes.0.key", valid_593926
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593927 = query.getOrDefault("Action")
  valid_593927 = validateParameter(valid_593927, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_593927 != nil:
    section.add "Action", valid_593927
  var valid_593928 = query.getOrDefault("attributes.1.key")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "attributes.1.key", valid_593928
  var valid_593929 = query.getOrDefault("attributes.0.value")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "attributes.0.value", valid_593929
  var valid_593930 = query.getOrDefault("Version")
  valid_593930 = validateParameter(valid_593930, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593930 != nil:
    section.add "Version", valid_593930
  var valid_593931 = query.getOrDefault("attributes.1.value")
  valid_593931 = validateParameter(valid_593931, JString, required = false,
                                 default = nil)
  if valid_593931 != nil:
    section.add "attributes.1.value", valid_593931
  var valid_593932 = query.getOrDefault("attributes.2.value")
  valid_593932 = validateParameter(valid_593932, JString, required = false,
                                 default = nil)
  if valid_593932 != nil:
    section.add "attributes.2.value", valid_593932
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593933 = header.getOrDefault("X-Amz-Signature")
  valid_593933 = validateParameter(valid_593933, JString, required = false,
                                 default = nil)
  if valid_593933 != nil:
    section.add "X-Amz-Signature", valid_593933
  var valid_593934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "X-Amz-Content-Sha256", valid_593934
  var valid_593935 = header.getOrDefault("X-Amz-Date")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "X-Amz-Date", valid_593935
  var valid_593936 = header.getOrDefault("X-Amz-Credential")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "X-Amz-Credential", valid_593936
  var valid_593937 = header.getOrDefault("X-Amz-Security-Token")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "X-Amz-Security-Token", valid_593937
  var valid_593938 = header.getOrDefault("X-Amz-Algorithm")
  valid_593938 = validateParameter(valid_593938, JString, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "X-Amz-Algorithm", valid_593938
  var valid_593939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593939 = validateParameter(valid_593939, JString, required = false,
                                 default = nil)
  if valid_593939 != nil:
    section.add "X-Amz-SignedHeaders", valid_593939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593940: Call_GetSetSMSAttributes_593922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_593940.validator(path, query, header, formData, body)
  let scheme = call_593940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593940.url(scheme.get, call_593940.host, call_593940.base,
                         call_593940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593940, url, valid)

proc call*(call_593941: Call_GetSetSMSAttributes_593922;
          attributes2Key: string = ""; attributes0Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Key: string = "";
          attributes0Value: string = ""; Version: string = "2010-03-31";
          attributes1Value: string = ""; attributes2Value: string = ""): Recallable =
  ## getSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Key: string
  ##   attributes0Key: string
  ##   Action: string (required)
  ##   attributes1Key: string
  ##   attributes0Value: string
  ##   Version: string (required)
  ##   attributes1Value: string
  ##   attributes2Value: string
  var query_593942 = newJObject()
  add(query_593942, "attributes.2.key", newJString(attributes2Key))
  add(query_593942, "attributes.0.key", newJString(attributes0Key))
  add(query_593942, "Action", newJString(Action))
  add(query_593942, "attributes.1.key", newJString(attributes1Key))
  add(query_593942, "attributes.0.value", newJString(attributes0Value))
  add(query_593942, "Version", newJString(Version))
  add(query_593942, "attributes.1.value", newJString(attributes1Value))
  add(query_593942, "attributes.2.value", newJString(attributes2Value))
  result = call_593941.call(nil, query_593942, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_593922(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_593923, base: "/",
    url: url_GetSetSMSAttributes_593924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_593983 = ref object of OpenApiRestCall_592364
proc url_PostSetSubscriptionAttributes_593985(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetSubscriptionAttributes_593984(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593986 = query.getOrDefault("Action")
  valid_593986 = validateParameter(valid_593986, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_593986 != nil:
    section.add "Action", valid_593986
  var valid_593987 = query.getOrDefault("Version")
  valid_593987 = validateParameter(valid_593987, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593987 != nil:
    section.add "Version", valid_593987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593988 = header.getOrDefault("X-Amz-Signature")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "X-Amz-Signature", valid_593988
  var valid_593989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "X-Amz-Content-Sha256", valid_593989
  var valid_593990 = header.getOrDefault("X-Amz-Date")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "X-Amz-Date", valid_593990
  var valid_593991 = header.getOrDefault("X-Amz-Credential")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = nil)
  if valid_593991 != nil:
    section.add "X-Amz-Credential", valid_593991
  var valid_593992 = header.getOrDefault("X-Amz-Security-Token")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "X-Amz-Security-Token", valid_593992
  var valid_593993 = header.getOrDefault("X-Amz-Algorithm")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "X-Amz-Algorithm", valid_593993
  var valid_593994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "X-Amz-SignedHeaders", valid_593994
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_593995 = formData.getOrDefault("AttributeName")
  valid_593995 = validateParameter(valid_593995, JString, required = true,
                                 default = nil)
  if valid_593995 != nil:
    section.add "AttributeName", valid_593995
  var valid_593996 = formData.getOrDefault("SubscriptionArn")
  valid_593996 = validateParameter(valid_593996, JString, required = true,
                                 default = nil)
  if valid_593996 != nil:
    section.add "SubscriptionArn", valid_593996
  var valid_593997 = formData.getOrDefault("AttributeValue")
  valid_593997 = validateParameter(valid_593997, JString, required = false,
                                 default = nil)
  if valid_593997 != nil:
    section.add "AttributeValue", valid_593997
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593998: Call_PostSetSubscriptionAttributes_593983; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_593998.validator(path, query, header, formData, body)
  let scheme = call_593998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593998.url(scheme.get, call_593998.host, call_593998.base,
                         call_593998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593998, url, valid)

proc call*(call_593999: Call_PostSetSubscriptionAttributes_593983;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594000 = newJObject()
  var formData_594001 = newJObject()
  add(formData_594001, "AttributeName", newJString(AttributeName))
  add(formData_594001, "SubscriptionArn", newJString(SubscriptionArn))
  add(formData_594001, "AttributeValue", newJString(AttributeValue))
  add(query_594000, "Action", newJString(Action))
  add(query_594000, "Version", newJString(Version))
  result = call_593999.call(nil, query_594000, nil, formData_594001, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_593983(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_593984, base: "/",
    url: url_PostSetSubscriptionAttributes_593985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_593965 = ref object of OpenApiRestCall_592364
proc url_GetSetSubscriptionAttributes_593967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetSubscriptionAttributes_593966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_593968 = query.getOrDefault("SubscriptionArn")
  valid_593968 = validateParameter(valid_593968, JString, required = true,
                                 default = nil)
  if valid_593968 != nil:
    section.add "SubscriptionArn", valid_593968
  var valid_593969 = query.getOrDefault("AttributeValue")
  valid_593969 = validateParameter(valid_593969, JString, required = false,
                                 default = nil)
  if valid_593969 != nil:
    section.add "AttributeValue", valid_593969
  var valid_593970 = query.getOrDefault("Action")
  valid_593970 = validateParameter(valid_593970, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_593970 != nil:
    section.add "Action", valid_593970
  var valid_593971 = query.getOrDefault("AttributeName")
  valid_593971 = validateParameter(valid_593971, JString, required = true,
                                 default = nil)
  if valid_593971 != nil:
    section.add "AttributeName", valid_593971
  var valid_593972 = query.getOrDefault("Version")
  valid_593972 = validateParameter(valid_593972, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_593972 != nil:
    section.add "Version", valid_593972
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593973 = header.getOrDefault("X-Amz-Signature")
  valid_593973 = validateParameter(valid_593973, JString, required = false,
                                 default = nil)
  if valid_593973 != nil:
    section.add "X-Amz-Signature", valid_593973
  var valid_593974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593974 = validateParameter(valid_593974, JString, required = false,
                                 default = nil)
  if valid_593974 != nil:
    section.add "X-Amz-Content-Sha256", valid_593974
  var valid_593975 = header.getOrDefault("X-Amz-Date")
  valid_593975 = validateParameter(valid_593975, JString, required = false,
                                 default = nil)
  if valid_593975 != nil:
    section.add "X-Amz-Date", valid_593975
  var valid_593976 = header.getOrDefault("X-Amz-Credential")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Credential", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-Security-Token")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-Security-Token", valid_593977
  var valid_593978 = header.getOrDefault("X-Amz-Algorithm")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-Algorithm", valid_593978
  var valid_593979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "X-Amz-SignedHeaders", valid_593979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593980: Call_GetSetSubscriptionAttributes_593965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_593980.validator(path, query, header, formData, body)
  let scheme = call_593980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593980.url(scheme.get, call_593980.host, call_593980.base,
                         call_593980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593980, url, valid)

proc call*(call_593981: Call_GetSetSubscriptionAttributes_593965;
          SubscriptionArn: string; AttributeName: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Version: string (required)
  var query_593982 = newJObject()
  add(query_593982, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_593982, "AttributeValue", newJString(AttributeValue))
  add(query_593982, "Action", newJString(Action))
  add(query_593982, "AttributeName", newJString(AttributeName))
  add(query_593982, "Version", newJString(Version))
  result = call_593981.call(nil, query_593982, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_593965(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_593966, base: "/",
    url: url_GetSetSubscriptionAttributes_593967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_594020 = ref object of OpenApiRestCall_592364
proc url_PostSetTopicAttributes_594022(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSetTopicAttributes_594021(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594023 = query.getOrDefault("Action")
  valid_594023 = validateParameter(valid_594023, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_594023 != nil:
    section.add "Action", valid_594023
  var valid_594024 = query.getOrDefault("Version")
  valid_594024 = validateParameter(valid_594024, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594024 != nil:
    section.add "Version", valid_594024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594025 = header.getOrDefault("X-Amz-Signature")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Signature", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-Content-Sha256", valid_594026
  var valid_594027 = header.getOrDefault("X-Amz-Date")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Date", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-Credential")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Credential", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-Security-Token")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-Security-Token", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Algorithm")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Algorithm", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-SignedHeaders", valid_594031
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_594032 = formData.getOrDefault("AttributeName")
  valid_594032 = validateParameter(valid_594032, JString, required = true,
                                 default = nil)
  if valid_594032 != nil:
    section.add "AttributeName", valid_594032
  var valid_594033 = formData.getOrDefault("TopicArn")
  valid_594033 = validateParameter(valid_594033, JString, required = true,
                                 default = nil)
  if valid_594033 != nil:
    section.add "TopicArn", valid_594033
  var valid_594034 = formData.getOrDefault("AttributeValue")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "AttributeValue", valid_594034
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594035: Call_PostSetTopicAttributes_594020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_594035.validator(path, query, header, formData, body)
  let scheme = call_594035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594035.url(scheme.get, call_594035.host, call_594035.base,
                         call_594035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594035, url, valid)

proc call*(call_594036: Call_PostSetTopicAttributes_594020; AttributeName: string;
          TopicArn: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594037 = newJObject()
  var formData_594038 = newJObject()
  add(formData_594038, "AttributeName", newJString(AttributeName))
  add(formData_594038, "TopicArn", newJString(TopicArn))
  add(formData_594038, "AttributeValue", newJString(AttributeValue))
  add(query_594037, "Action", newJString(Action))
  add(query_594037, "Version", newJString(Version))
  result = call_594036.call(nil, query_594037, nil, formData_594038, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_594020(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_594021, base: "/",
    url: url_PostSetTopicAttributes_594022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_594002 = ref object of OpenApiRestCall_592364
proc url_GetSetTopicAttributes_594004(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSetTopicAttributes_594003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  section = newJObject()
  var valid_594005 = query.getOrDefault("AttributeValue")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "AttributeValue", valid_594005
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594006 = query.getOrDefault("Action")
  valid_594006 = validateParameter(valid_594006, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_594006 != nil:
    section.add "Action", valid_594006
  var valid_594007 = query.getOrDefault("AttributeName")
  valid_594007 = validateParameter(valid_594007, JString, required = true,
                                 default = nil)
  if valid_594007 != nil:
    section.add "AttributeName", valid_594007
  var valid_594008 = query.getOrDefault("Version")
  valid_594008 = validateParameter(valid_594008, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594008 != nil:
    section.add "Version", valid_594008
  var valid_594009 = query.getOrDefault("TopicArn")
  valid_594009 = validateParameter(valid_594009, JString, required = true,
                                 default = nil)
  if valid_594009 != nil:
    section.add "TopicArn", valid_594009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594010 = header.getOrDefault("X-Amz-Signature")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Signature", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-Content-Sha256", valid_594011
  var valid_594012 = header.getOrDefault("X-Amz-Date")
  valid_594012 = validateParameter(valid_594012, JString, required = false,
                                 default = nil)
  if valid_594012 != nil:
    section.add "X-Amz-Date", valid_594012
  var valid_594013 = header.getOrDefault("X-Amz-Credential")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-Credential", valid_594013
  var valid_594014 = header.getOrDefault("X-Amz-Security-Token")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-Security-Token", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Algorithm")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Algorithm", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-SignedHeaders", valid_594016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594017: Call_GetSetTopicAttributes_594002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_594017.validator(path, query, header, formData, body)
  let scheme = call_594017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594017.url(scheme.get, call_594017.host, call_594017.base,
                         call_594017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594017, url, valid)

proc call*(call_594018: Call_GetSetTopicAttributes_594002; AttributeName: string;
          TopicArn: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  var query_594019 = newJObject()
  add(query_594019, "AttributeValue", newJString(AttributeValue))
  add(query_594019, "Action", newJString(Action))
  add(query_594019, "AttributeName", newJString(AttributeName))
  add(query_594019, "Version", newJString(Version))
  add(query_594019, "TopicArn", newJString(TopicArn))
  result = call_594018.call(nil, query_594019, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_594002(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_594003, base: "/",
    url: url_GetSetTopicAttributes_594004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_594064 = ref object of OpenApiRestCall_592364
proc url_PostSubscribe_594066(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSubscribe_594065(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594067 = query.getOrDefault("Action")
  valid_594067 = validateParameter(valid_594067, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_594067 != nil:
    section.add "Action", valid_594067
  var valid_594068 = query.getOrDefault("Version")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594068 != nil:
    section.add "Version", valid_594068
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594069 = header.getOrDefault("X-Amz-Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Signature", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Content-Sha256", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Date")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Date", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Credential")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Credential", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Security-Token")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Security-Token", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Algorithm")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Algorithm", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-SignedHeaders", valid_594075
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_594076 = formData.getOrDefault("Endpoint")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "Endpoint", valid_594076
  var valid_594077 = formData.getOrDefault("Attributes.0.key")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "Attributes.0.key", valid_594077
  var valid_594078 = formData.getOrDefault("Attributes.2.value")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "Attributes.2.value", valid_594078
  var valid_594079 = formData.getOrDefault("Attributes.2.key")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "Attributes.2.key", valid_594079
  assert formData != nil,
        "formData argument is necessary due to required `Protocol` field"
  var valid_594080 = formData.getOrDefault("Protocol")
  valid_594080 = validateParameter(valid_594080, JString, required = true,
                                 default = nil)
  if valid_594080 != nil:
    section.add "Protocol", valid_594080
  var valid_594081 = formData.getOrDefault("Attributes.0.value")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "Attributes.0.value", valid_594081
  var valid_594082 = formData.getOrDefault("Attributes.1.key")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "Attributes.1.key", valid_594082
  var valid_594083 = formData.getOrDefault("TopicArn")
  valid_594083 = validateParameter(valid_594083, JString, required = true,
                                 default = nil)
  if valid_594083 != nil:
    section.add "TopicArn", valid_594083
  var valid_594084 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_594084 = validateParameter(valid_594084, JBool, required = false, default = nil)
  if valid_594084 != nil:
    section.add "ReturnSubscriptionArn", valid_594084
  var valid_594085 = formData.getOrDefault("Attributes.1.value")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "Attributes.1.value", valid_594085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_PostSubscribe_594064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_PostSubscribe_594064; Protocol: string;
          TopicArn: string; Endpoint: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_594088 = newJObject()
  var formData_594089 = newJObject()
  add(formData_594089, "Endpoint", newJString(Endpoint))
  add(formData_594089, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_594089, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_594089, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_594089, "Protocol", newJString(Protocol))
  add(formData_594089, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_594089, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_594089, "TopicArn", newJString(TopicArn))
  add(formData_594089, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_594088, "Action", newJString(Action))
  add(query_594088, "Version", newJString(Version))
  add(formData_594089, "Attributes.1.value", newJString(Attributes1Value))
  result = call_594087.call(nil, query_594088, nil, formData_594089, nil)

var postSubscribe* = Call_PostSubscribe_594064(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_594065,
    base: "/", url: url_PostSubscribe_594066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_594039 = ref object of OpenApiRestCall_592364
proc url_GetSubscribe_594041(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSubscribe_594040(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Action: JString (required)
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  section = newJObject()
  var valid_594042 = query.getOrDefault("Attributes.1.key")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "Attributes.1.key", valid_594042
  var valid_594043 = query.getOrDefault("Attributes.0.value")
  valid_594043 = validateParameter(valid_594043, JString, required = false,
                                 default = nil)
  if valid_594043 != nil:
    section.add "Attributes.0.value", valid_594043
  var valid_594044 = query.getOrDefault("Endpoint")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "Endpoint", valid_594044
  var valid_594045 = query.getOrDefault("Attributes.0.key")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "Attributes.0.key", valid_594045
  var valid_594046 = query.getOrDefault("Attributes.2.value")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "Attributes.2.value", valid_594046
  var valid_594047 = query.getOrDefault("Attributes.1.value")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "Attributes.1.value", valid_594047
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594048 = query.getOrDefault("Action")
  valid_594048 = validateParameter(valid_594048, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_594048 != nil:
    section.add "Action", valid_594048
  var valid_594049 = query.getOrDefault("Protocol")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = nil)
  if valid_594049 != nil:
    section.add "Protocol", valid_594049
  var valid_594050 = query.getOrDefault("ReturnSubscriptionArn")
  valid_594050 = validateParameter(valid_594050, JBool, required = false, default = nil)
  if valid_594050 != nil:
    section.add "ReturnSubscriptionArn", valid_594050
  var valid_594051 = query.getOrDefault("Version")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594051 != nil:
    section.add "Version", valid_594051
  var valid_594052 = query.getOrDefault("Attributes.2.key")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "Attributes.2.key", valid_594052
  var valid_594053 = query.getOrDefault("TopicArn")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = nil)
  if valid_594053 != nil:
    section.add "TopicArn", valid_594053
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594054 = header.getOrDefault("X-Amz-Signature")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Signature", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Content-Sha256", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Date")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Date", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Security-Token")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Security-Token", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Algorithm")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Algorithm", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-SignedHeaders", valid_594060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594061: Call_GetSubscribe_594039; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_594061.validator(path, query, header, formData, body)
  let scheme = call_594061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594061.url(scheme.get, call_594061.host, call_594061.base,
                         call_594061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594061, url, valid)

proc call*(call_594062: Call_GetSubscribe_594039; Protocol: string; TopicArn: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Endpoint: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Action: string (required)
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Version: string (required)
  ##   Attributes2Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  var query_594063 = newJObject()
  add(query_594063, "Attributes.1.key", newJString(Attributes1Key))
  add(query_594063, "Attributes.0.value", newJString(Attributes0Value))
  add(query_594063, "Endpoint", newJString(Endpoint))
  add(query_594063, "Attributes.0.key", newJString(Attributes0Key))
  add(query_594063, "Attributes.2.value", newJString(Attributes2Value))
  add(query_594063, "Attributes.1.value", newJString(Attributes1Value))
  add(query_594063, "Action", newJString(Action))
  add(query_594063, "Protocol", newJString(Protocol))
  add(query_594063, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_594063, "Version", newJString(Version))
  add(query_594063, "Attributes.2.key", newJString(Attributes2Key))
  add(query_594063, "TopicArn", newJString(TopicArn))
  result = call_594062.call(nil, query_594063, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_594039(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_594040, base: "/",
    url: url_GetSubscribe_594041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_594107 = ref object of OpenApiRestCall_592364
proc url_PostTagResource_594109(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTagResource_594108(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594110 = query.getOrDefault("Action")
  valid_594110 = validateParameter(valid_594110, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_594110 != nil:
    section.add "Action", valid_594110
  var valid_594111 = query.getOrDefault("Version")
  valid_594111 = validateParameter(valid_594111, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594111 != nil:
    section.add "Version", valid_594111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Content-Sha256", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Date")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Date", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Credential")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Credential", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Security-Token")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Security-Token", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Algorithm")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Algorithm", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-SignedHeaders", valid_594118
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_594119 = formData.getOrDefault("ResourceArn")
  valid_594119 = validateParameter(valid_594119, JString, required = true,
                                 default = nil)
  if valid_594119 != nil:
    section.add "ResourceArn", valid_594119
  var valid_594120 = formData.getOrDefault("Tags")
  valid_594120 = validateParameter(valid_594120, JArray, required = true, default = nil)
  if valid_594120 != nil:
    section.add "Tags", valid_594120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594121: Call_PostTagResource_594107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_594121.validator(path, query, header, formData, body)
  let scheme = call_594121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594121.url(scheme.get, call_594121.host, call_594121.base,
                         call_594121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594121, url, valid)

proc call*(call_594122: Call_PostTagResource_594107; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Version: string (required)
  var query_594123 = newJObject()
  var formData_594124 = newJObject()
  add(formData_594124, "ResourceArn", newJString(ResourceArn))
  add(query_594123, "Action", newJString(Action))
  if Tags != nil:
    formData_594124.add "Tags", Tags
  add(query_594123, "Version", newJString(Version))
  result = call_594122.call(nil, query_594123, nil, formData_594124, nil)

var postTagResource* = Call_PostTagResource_594107(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_594108,
    base: "/", url: url_PostTagResource_594109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_594090 = ref object of OpenApiRestCall_592364
proc url_GetTagResource_594092(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTagResource_594091(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_594093 = query.getOrDefault("Tags")
  valid_594093 = validateParameter(valid_594093, JArray, required = true, default = nil)
  if valid_594093 != nil:
    section.add "Tags", valid_594093
  var valid_594094 = query.getOrDefault("ResourceArn")
  valid_594094 = validateParameter(valid_594094, JString, required = true,
                                 default = nil)
  if valid_594094 != nil:
    section.add "ResourceArn", valid_594094
  var valid_594095 = query.getOrDefault("Action")
  valid_594095 = validateParameter(valid_594095, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_594095 != nil:
    section.add "Action", valid_594095
  var valid_594096 = query.getOrDefault("Version")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594096 != nil:
    section.add "Version", valid_594096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Content-Sha256", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Date")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Date", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Credential")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Credential", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Security-Token")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Security-Token", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Algorithm")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Algorithm", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-SignedHeaders", valid_594103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594104: Call_GetTagResource_594090; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_594104.validator(path, query, header, formData, body)
  let scheme = call_594104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594104.url(scheme.get, call_594104.host, call_594104.base,
                         call_594104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594104, url, valid)

proc call*(call_594105: Call_GetTagResource_594090; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594106 = newJObject()
  if Tags != nil:
    query_594106.add "Tags", Tags
  add(query_594106, "ResourceArn", newJString(ResourceArn))
  add(query_594106, "Action", newJString(Action))
  add(query_594106, "Version", newJString(Version))
  result = call_594105.call(nil, query_594106, nil, nil, nil)

var getTagResource* = Call_GetTagResource_594090(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_594091,
    base: "/", url: url_GetTagResource_594092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_594141 = ref object of OpenApiRestCall_592364
proc url_PostUnsubscribe_594143(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUnsubscribe_594142(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594144 = query.getOrDefault("Action")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_594144 != nil:
    section.add "Action", valid_594144
  var valid_594145 = query.getOrDefault("Version")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594145 != nil:
    section.add "Version", valid_594145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594146 = header.getOrDefault("X-Amz-Signature")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Signature", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Content-Sha256", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Date")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Date", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Credential")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Credential", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Security-Token")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Security-Token", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Algorithm", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-SignedHeaders", valid_594152
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_594153 = formData.getOrDefault("SubscriptionArn")
  valid_594153 = validateParameter(valid_594153, JString, required = true,
                                 default = nil)
  if valid_594153 != nil:
    section.add "SubscriptionArn", valid_594153
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594154: Call_PostUnsubscribe_594141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_594154.validator(path, query, header, formData, body)
  let scheme = call_594154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594154.url(scheme.get, call_594154.host, call_594154.base,
                         call_594154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594154, url, valid)

proc call*(call_594155: Call_PostUnsubscribe_594141; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594156 = newJObject()
  var formData_594157 = newJObject()
  add(formData_594157, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_594156, "Action", newJString(Action))
  add(query_594156, "Version", newJString(Version))
  result = call_594155.call(nil, query_594156, nil, formData_594157, nil)

var postUnsubscribe* = Call_PostUnsubscribe_594141(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_594142,
    base: "/", url: url_PostUnsubscribe_594143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_594125 = ref object of OpenApiRestCall_592364
proc url_GetUnsubscribe_594127(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUnsubscribe_594126(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_594128 = query.getOrDefault("SubscriptionArn")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = nil)
  if valid_594128 != nil:
    section.add "SubscriptionArn", valid_594128
  var valid_594129 = query.getOrDefault("Action")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_594129 != nil:
    section.add "Action", valid_594129
  var valid_594130 = query.getOrDefault("Version")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594130 != nil:
    section.add "Version", valid_594130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594131 = header.getOrDefault("X-Amz-Signature")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Signature", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Content-Sha256", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Date")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Date", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Credential")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Credential", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Security-Token")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Security-Token", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Algorithm")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Algorithm", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-SignedHeaders", valid_594137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_GetUnsubscribe_594125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_GetUnsubscribe_594125; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594140 = newJObject()
  add(query_594140, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_594140, "Action", newJString(Action))
  add(query_594140, "Version", newJString(Version))
  result = call_594139.call(nil, query_594140, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_594125(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_594126,
    base: "/", url: url_GetUnsubscribe_594127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_594175 = ref object of OpenApiRestCall_592364
proc url_PostUntagResource_594177(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUntagResource_594176(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594178 = query.getOrDefault("Action")
  valid_594178 = validateParameter(valid_594178, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_594178 != nil:
    section.add "Action", valid_594178
  var valid_594179 = query.getOrDefault("Version")
  valid_594179 = validateParameter(valid_594179, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594179 != nil:
    section.add "Version", valid_594179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Content-Sha256", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Security-Token")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Security-Token", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-SignedHeaders", valid_594186
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_594187 = formData.getOrDefault("TagKeys")
  valid_594187 = validateParameter(valid_594187, JArray, required = true, default = nil)
  if valid_594187 != nil:
    section.add "TagKeys", valid_594187
  var valid_594188 = formData.getOrDefault("ResourceArn")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = nil)
  if valid_594188 != nil:
    section.add "ResourceArn", valid_594188
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594189: Call_PostUntagResource_594175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_594189.validator(path, query, header, formData, body)
  let scheme = call_594189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594189.url(scheme.get, call_594189.host, call_594189.base,
                         call_594189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594189, url, valid)

proc call*(call_594190: Call_PostUntagResource_594175; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594191 = newJObject()
  var formData_594192 = newJObject()
  if TagKeys != nil:
    formData_594192.add "TagKeys", TagKeys
  add(formData_594192, "ResourceArn", newJString(ResourceArn))
  add(query_594191, "Action", newJString(Action))
  add(query_594191, "Version", newJString(Version))
  result = call_594190.call(nil, query_594191, nil, formData_594192, nil)

var postUntagResource* = Call_PostUntagResource_594175(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_594176,
    base: "/", url: url_PostUntagResource_594177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_594158 = ref object of OpenApiRestCall_592364
proc url_GetUntagResource_594160(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUntagResource_594159(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_594161 = query.getOrDefault("TagKeys")
  valid_594161 = validateParameter(valid_594161, JArray, required = true, default = nil)
  if valid_594161 != nil:
    section.add "TagKeys", valid_594161
  var valid_594162 = query.getOrDefault("ResourceArn")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "ResourceArn", valid_594162
  var valid_594163 = query.getOrDefault("Action")
  valid_594163 = validateParameter(valid_594163, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_594163 != nil:
    section.add "Action", valid_594163
  var valid_594164 = query.getOrDefault("Version")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_594164 != nil:
    section.add "Version", valid_594164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Content-Sha256", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Date")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Date", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Security-Token")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Security-Token", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-SignedHeaders", valid_594171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594172: Call_GetUntagResource_594158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_594172.validator(path, query, header, formData, body)
  let scheme = call_594172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594172.url(scheme.get, call_594172.host, call_594172.base,
                         call_594172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594172, url, valid)

proc call*(call_594173: Call_GetUntagResource_594158; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594174 = newJObject()
  if TagKeys != nil:
    query_594174.add "TagKeys", TagKeys
  add(query_594174, "ResourceArn", newJString(ResourceArn))
  add(query_594174, "Action", newJString(Action))
  add(query_594174, "Version", newJString(Version))
  result = call_594173.call(nil, query_594174, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_594158(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_594159,
    base: "/", url: url_GetUntagResource_594160,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
