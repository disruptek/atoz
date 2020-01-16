
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Application Discovery Service
## version: 2015-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Application Discovery Service</fullname> <p>AWS Application Discovery Service helps you plan application migration projects by automatically identifying servers, virtual machines (VMs), software, and software dependencies running in your on-premises data centers. Application Discovery Service also collects application performance data, which can help you assess the outcome of your migration. The data collected by Application Discovery Service is securely retained in an AWS-hosted and managed database in the cloud. You can export the data as a CSV or XML file into your preferred visualization tool or cloud-migration solution to plan your migration. For more information, see <a href="http://aws.amazon.com/application-discovery/faqs/">AWS Application Discovery Service FAQ</a>.</p> <p>Application Discovery Service offers two modes of operation:</p> <ul> <li> <p> <b>Agentless discovery</b> mode is recommended for environments that use VMware vCenter Server. This mode doesn't require you to install an agent on each host. Agentless discovery gathers server information regardless of the operating systems, which minimizes the time required for initial on-premises infrastructure assessment. Agentless discovery doesn't collect information about software and software dependencies. It also doesn't work in non-VMware environments. </p> </li> <li> <p> <b>Agent-based discovery</b> mode collects a richer set of data than agentless discovery by using the AWS Application Discovery Agent, which you install on one or more hosts in your data center. The agent captures infrastructure and application information, including an inventory of installed software applications, system and process performance, resource utilization, and network dependencies between workloads. The information collected by agents is secured at rest and in transit to the Application Discovery Service database in the cloud. </p> </li> </ul> <p>We recommend that you use agent-based discovery for non-VMware environments and to collect information about software and software dependencies. You can also run agent-based and agentless discovery simultaneously. Use agentless discovery to quickly complete the initial infrastructure assessment and then install agents on select hosts.</p> <p>Application Discovery Service integrates with application discovery solutions from AWS Partner Network (APN) partners. Third-party application discovery tools can query Application Discovery Service and write to the Application Discovery Service database using a public API. You can then import the data into either a visualization tool or cloud-migration solution.</p> <important> <p>Application Discovery Service doesn't gather sensitive information. All data is handled according to the <a href="http://aws.amazon.com/privacy/">AWS Privacy Policy</a>. You can operate Application Discovery Service offline to inspect collected data before it is shared with the service.</p> </important> <p>This API reference provides descriptions, syntax, and usage examples for each of the actions and data types for Application Discovery Service. The topic for each action shows the API request parameters and the response. Alternatively, you can use one of the AWS SDKs to access an API that is tailored to the programming language or platform that you're using. For more information, see <a href="http://aws.amazon.com/tools/#SDKs">AWS SDKs</a>.</p> <p>This guide is intended for use with the <a href="http://docs.aws.amazon.com/application-discovery/latest/userguide/"> <i>AWS Application Discovery Service User Guide</i> </a>.</p> <note> <p>Remember that you must set your AWS Migration Hub home region before you call any of these APIs, or a <code>HomeRegionNotSetException</code> error will be returned. Also, you must make the API calls while in your home region.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/discovery/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "discovery.ap-northeast-1.amazonaws.com", "ap-southeast-1": "discovery.ap-southeast-1.amazonaws.com",
                           "us-west-2": "discovery.us-west-2.amazonaws.com",
                           "eu-west-2": "discovery.eu-west-2.amazonaws.com", "ap-northeast-3": "discovery.ap-northeast-3.amazonaws.com", "eu-central-1": "discovery.eu-central-1.amazonaws.com",
                           "us-east-2": "discovery.us-east-2.amazonaws.com",
                           "us-east-1": "discovery.us-east-1.amazonaws.com", "cn-northwest-1": "discovery.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "discovery.ap-south-1.amazonaws.com",
                           "eu-north-1": "discovery.eu-north-1.amazonaws.com", "ap-northeast-2": "discovery.ap-northeast-2.amazonaws.com",
                           "us-west-1": "discovery.us-west-1.amazonaws.com", "us-gov-east-1": "discovery.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "discovery.eu-west-3.amazonaws.com", "cn-north-1": "discovery.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "discovery.sa-east-1.amazonaws.com",
                           "eu-west-1": "discovery.eu-west-1.amazonaws.com", "us-gov-west-1": "discovery.us-gov-west-1.amazonaws.com", "ap-southeast-2": "discovery.ap-southeast-2.amazonaws.com", "ca-central-1": "discovery.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "discovery.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "discovery.ap-southeast-1.amazonaws.com",
      "us-west-2": "discovery.us-west-2.amazonaws.com",
      "eu-west-2": "discovery.eu-west-2.amazonaws.com",
      "ap-northeast-3": "discovery.ap-northeast-3.amazonaws.com",
      "eu-central-1": "discovery.eu-central-1.amazonaws.com",
      "us-east-2": "discovery.us-east-2.amazonaws.com",
      "us-east-1": "discovery.us-east-1.amazonaws.com",
      "cn-northwest-1": "discovery.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "discovery.ap-south-1.amazonaws.com",
      "eu-north-1": "discovery.eu-north-1.amazonaws.com",
      "ap-northeast-2": "discovery.ap-northeast-2.amazonaws.com",
      "us-west-1": "discovery.us-west-1.amazonaws.com",
      "us-gov-east-1": "discovery.us-gov-east-1.amazonaws.com",
      "eu-west-3": "discovery.eu-west-3.amazonaws.com",
      "cn-north-1": "discovery.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "discovery.sa-east-1.amazonaws.com",
      "eu-west-1": "discovery.eu-west-1.amazonaws.com",
      "us-gov-west-1": "discovery.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "discovery.ap-southeast-2.amazonaws.com",
      "ca-central-1": "discovery.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "discovery"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateConfigurationItemsToApplication_605927 = ref object of OpenApiRestCall_605589
proc url_AssociateConfigurationItemsToApplication_605929(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateConfigurationItemsToApplication_605928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates one or more configuration items with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AssociateConfigurationItemsToApplication_605927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates one or more configuration items with an application.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AssociateConfigurationItemsToApplication_605927;
          body: JsonNode): Recallable =
  ## associateConfigurationItemsToApplication
  ## Associates one or more configuration items with an application.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var associateConfigurationItemsToApplication* = Call_AssociateConfigurationItemsToApplication_605927(
    name: "associateConfigurationItemsToApplication", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication",
    validator: validate_AssociateConfigurationItemsToApplication_605928,
    base: "/", url: url_AssociateConfigurationItemsToApplication_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImportData_606196 = ref object of OpenApiRestCall_605589
proc url_BatchDeleteImportData_606198(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteImportData_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.BatchDeleteImportData"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_BatchDeleteImportData_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_BatchDeleteImportData_606196; body: JsonNode): Recallable =
  ## batchDeleteImportData
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var batchDeleteImportData* = Call_BatchDeleteImportData_606196(
    name: "batchDeleteImportData", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.BatchDeleteImportData",
    validator: validate_BatchDeleteImportData_606197, base: "/",
    url: url_BatchDeleteImportData_606198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_606211 = ref object of OpenApiRestCall_605589
proc url_CreateApplication_606213(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_606212(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an application with the given name and description.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateApplication"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreateApplication_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application with the given name and description.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateApplication_606211; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application with the given name and description.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createApplication* = Call_CreateApplication_606211(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateApplication",
    validator: validate_CreateApplication_606212, base: "/",
    url: url_CreateApplication_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_606226 = ref object of OpenApiRestCall_605589
proc url_CreateTags_606228(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTags_606227(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateTags"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_CreateTags_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateTags_606226; body: JsonNode): Recallable =
  ## createTags
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createTags* = Call_CreateTags_606226(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateTags",
                                      validator: validate_CreateTags_606227,
                                      base: "/", url: url_CreateTags_606228,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplications_606241 = ref object of OpenApiRestCall_605589
proc url_DeleteApplications_606243(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplications_606242(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteApplications"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeleteApplications_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeleteApplications_606241; body: JsonNode): Recallable =
  ## deleteApplications
  ## Deletes a list of applications and their associations with configuration items.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deleteApplications* = Call_DeleteApplications_606241(
    name: "deleteApplications", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteApplications",
    validator: validate_DeleteApplications_606242, base: "/",
    url: url_DeleteApplications_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_606256 = ref object of OpenApiRestCall_605589
proc url_DeleteTags_606258(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_606257(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteTags"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_DeleteTags_606256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DeleteTags_606256; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var deleteTags* = Call_DeleteTags_606256(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteTags",
                                      validator: validate_DeleteTags_606257,
                                      base: "/", url: url_DeleteTags_606258,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgents_606271 = ref object of OpenApiRestCall_605589
proc url_DescribeAgents_606273(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAgents_606272(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeAgents"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_DescribeAgents_606271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DescribeAgents_606271; body: JsonNode): Recallable =
  ## describeAgents
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var describeAgents* = Call_DescribeAgents_606271(name: "describeAgents",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeAgents",
    validator: validate_DescribeAgents_606272, base: "/", url: url_DescribeAgents_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurations_606286 = ref object of OpenApiRestCall_605589
proc url_DescribeConfigurations_606288(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurations_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="http://docs.aws.amazon.com/application-discovery/latest/APIReference/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeConfigurations"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_DescribeConfigurations_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="http://docs.aws.amazon.com/application-discovery/latest/APIReference/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a>.</p> </note>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DescribeConfigurations_606286; body: JsonNode): Recallable =
  ## describeConfigurations
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="http://docs.aws.amazon.com/application-discovery/latest/APIReference/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a>.</p> </note>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var describeConfigurations* = Call_DescribeConfigurations_606286(
    name: "describeConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeConfigurations",
    validator: validate_DescribeConfigurations_606287, base: "/",
    url: url_DescribeConfigurations_606288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousExports_606301 = ref object of OpenApiRestCall_605589
proc url_DescribeContinuousExports_606303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeContinuousExports_606302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606304 = query.getOrDefault("nextToken")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "nextToken", valid_606304
  var valid_606305 = query.getOrDefault("maxResults")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "maxResults", valid_606305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606306 = header.getOrDefault("X-Amz-Target")
  valid_606306 = validateParameter(valid_606306, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeContinuousExports"))
  if valid_606306 != nil:
    section.add "X-Amz-Target", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Signature")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Signature", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Content-Sha256", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Date")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Date", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Credential")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Credential", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Security-Token")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Security-Token", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Algorithm")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Algorithm", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-SignedHeaders", valid_606313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606315: Call_DescribeContinuousExports_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  let valid = call_606315.validator(path, query, header, formData, body)
  let scheme = call_606315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606315.url(scheme.get, call_606315.host, call_606315.base,
                         call_606315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606315, url, valid)

proc call*(call_606316: Call_DescribeContinuousExports_606301; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeContinuousExports
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606317 = newJObject()
  var body_606318 = newJObject()
  add(query_606317, "nextToken", newJString(nextToken))
  if body != nil:
    body_606318 = body
  add(query_606317, "maxResults", newJString(maxResults))
  result = call_606316.call(nil, query_606317, nil, nil, body_606318)

var describeContinuousExports* = Call_DescribeContinuousExports_606301(
    name: "describeContinuousExports", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeContinuousExports",
    validator: validate_DescribeContinuousExports_606302, base: "/",
    url: url_DescribeContinuousExports_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportConfigurations_606320 = ref object of OpenApiRestCall_605589
proc url_DescribeExportConfigurations_606322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportConfigurations_606321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606323 = header.getOrDefault("X-Amz-Target")
  valid_606323 = validateParameter(valid_606323, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportConfigurations"))
  if valid_606323 != nil:
    section.add "X-Amz-Target", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Signature")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Signature", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Content-Sha256", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Date")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Date", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Credential")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Credential", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Security-Token")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Security-Token", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Algorithm")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Algorithm", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-SignedHeaders", valid_606330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606332: Call_DescribeExportConfigurations_606320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  let valid = call_606332.validator(path, query, header, formData, body)
  let scheme = call_606332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606332.url(scheme.get, call_606332.host, call_606332.base,
                         call_606332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606332, url, valid)

proc call*(call_606333: Call_DescribeExportConfigurations_606320; body: JsonNode): Recallable =
  ## describeExportConfigurations
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ##   body: JObject (required)
  var body_606334 = newJObject()
  if body != nil:
    body_606334 = body
  result = call_606333.call(nil, nil, nil, nil, body_606334)

var describeExportConfigurations* = Call_DescribeExportConfigurations_606320(
    name: "describeExportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportConfigurations",
    validator: validate_DescribeExportConfigurations_606321, base: "/",
    url: url_DescribeExportConfigurations_606322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_606335 = ref object of OpenApiRestCall_605589
proc url_DescribeExportTasks_606337(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportTasks_606336(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606338 = header.getOrDefault("X-Amz-Target")
  valid_606338 = validateParameter(valid_606338, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportTasks"))
  if valid_606338 != nil:
    section.add "X-Amz-Target", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Signature")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Signature", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Content-Sha256", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Date")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Date", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Credential")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Credential", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Security-Token")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Security-Token", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Algorithm")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Algorithm", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-SignedHeaders", valid_606345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606347: Call_DescribeExportTasks_606335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  let valid = call_606347.validator(path, query, header, formData, body)
  let scheme = call_606347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606347.url(scheme.get, call_606347.host, call_606347.base,
                         call_606347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606347, url, valid)

proc call*(call_606348: Call_DescribeExportTasks_606335; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ##   body: JObject (required)
  var body_606349 = newJObject()
  if body != nil:
    body_606349 = body
  result = call_606348.call(nil, nil, nil, nil, body_606349)

var describeExportTasks* = Call_DescribeExportTasks_606335(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportTasks",
    validator: validate_DescribeExportTasks_606336, base: "/",
    url: url_DescribeExportTasks_606337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImportTasks_606350 = ref object of OpenApiRestCall_605589
proc url_DescribeImportTasks_606352(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImportTasks_606351(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_606353 = query.getOrDefault("nextToken")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "nextToken", valid_606353
  var valid_606354 = query.getOrDefault("maxResults")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "maxResults", valid_606354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606355 = header.getOrDefault("X-Amz-Target")
  valid_606355 = validateParameter(valid_606355, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeImportTasks"))
  if valid_606355 != nil:
    section.add "X-Amz-Target", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Signature")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Signature", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Content-Sha256", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Date")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Date", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Credential")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Credential", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Security-Token")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Security-Token", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Algorithm")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Algorithm", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-SignedHeaders", valid_606362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606364: Call_DescribeImportTasks_606350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  let valid = call_606364.validator(path, query, header, formData, body)
  let scheme = call_606364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606364.url(scheme.get, call_606364.host, call_606364.base,
                         call_606364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606364, url, valid)

proc call*(call_606365: Call_DescribeImportTasks_606350; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImportTasks
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606366 = newJObject()
  var body_606367 = newJObject()
  add(query_606366, "nextToken", newJString(nextToken))
  if body != nil:
    body_606367 = body
  add(query_606366, "maxResults", newJString(maxResults))
  result = call_606365.call(nil, query_606366, nil, nil, body_606367)

var describeImportTasks* = Call_DescribeImportTasks_606350(
    name: "describeImportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeImportTasks",
    validator: validate_DescribeImportTasks_606351, base: "/",
    url: url_DescribeImportTasks_606352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_606368 = ref object of OpenApiRestCall_605589
proc url_DescribeTags_606370(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_606369(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606371 = header.getOrDefault("X-Amz-Target")
  valid_606371 = validateParameter(valid_606371, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeTags"))
  if valid_606371 != nil:
    section.add "X-Amz-Target", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Signature")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Signature", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Content-Sha256", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Date")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Date", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Credential")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Credential", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Security-Token")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Security-Token", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Algorithm")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Algorithm", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-SignedHeaders", valid_606378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606380: Call_DescribeTags_606368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  let valid = call_606380.validator(path, query, header, formData, body)
  let scheme = call_606380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606380.url(scheme.get, call_606380.host, call_606380.base,
                         call_606380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606380, url, valid)

proc call*(call_606381: Call_DescribeTags_606368; body: JsonNode): Recallable =
  ## describeTags
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ##   body: JObject (required)
  var body_606382 = newJObject()
  if body != nil:
    body_606382 = body
  result = call_606381.call(nil, nil, nil, nil, body_606382)

var describeTags* = Call_DescribeTags_606368(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeTags",
    validator: validate_DescribeTags_606369, base: "/", url: url_DescribeTags_606370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConfigurationItemsFromApplication_606383 = ref object of OpenApiRestCall_605589
proc url_DisassociateConfigurationItemsFromApplication_606385(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConfigurationItemsFromApplication_606384(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Disassociates one or more configuration items from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606386 = header.getOrDefault("X-Amz-Target")
  valid_606386 = validateParameter(valid_606386, JString, required = true, default = newJString("AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication"))
  if valid_606386 != nil:
    section.add "X-Amz-Target", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Signature")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Signature", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Content-Sha256", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Date")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Date", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Credential")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Credential", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Security-Token")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Security-Token", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Algorithm")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Algorithm", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-SignedHeaders", valid_606393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606395: Call_DisassociateConfigurationItemsFromApplication_606383;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates one or more configuration items from an application.
  ## 
  let valid = call_606395.validator(path, query, header, formData, body)
  let scheme = call_606395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606395.url(scheme.get, call_606395.host, call_606395.base,
                         call_606395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606395, url, valid)

proc call*(call_606396: Call_DisassociateConfigurationItemsFromApplication_606383;
          body: JsonNode): Recallable =
  ## disassociateConfigurationItemsFromApplication
  ## Disassociates one or more configuration items from an application.
  ##   body: JObject (required)
  var body_606397 = newJObject()
  if body != nil:
    body_606397 = body
  result = call_606396.call(nil, nil, nil, nil, body_606397)

var disassociateConfigurationItemsFromApplication* = Call_DisassociateConfigurationItemsFromApplication_606383(
    name: "disassociateConfigurationItemsFromApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication",
    validator: validate_DisassociateConfigurationItemsFromApplication_606384,
    base: "/", url: url_DisassociateConfigurationItemsFromApplication_606385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportConfigurations_606398 = ref object of OpenApiRestCall_605589
proc url_ExportConfigurations_606400(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportConfigurations_606399(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606401 = header.getOrDefault("X-Amz-Target")
  valid_606401 = validateParameter(valid_606401, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ExportConfigurations"))
  if valid_606401 != nil:
    section.add "X-Amz-Target", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Signature")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Signature", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Content-Sha256", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Date")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Date", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Credential")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Credential", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Security-Token")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Security-Token", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Algorithm")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Algorithm", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-SignedHeaders", valid_606408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606409: Call_ExportConfigurations_606398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  let valid = call_606409.validator(path, query, header, formData, body)
  let scheme = call_606409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606409.url(scheme.get, call_606409.host, call_606409.base,
                         call_606409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606409, url, valid)

proc call*(call_606410: Call_ExportConfigurations_606398): Recallable =
  ## exportConfigurations
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  result = call_606410.call(nil, nil, nil, nil, nil)

var exportConfigurations* = Call_ExportConfigurations_606398(
    name: "exportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ExportConfigurations",
    validator: validate_ExportConfigurations_606399, base: "/",
    url: url_ExportConfigurations_606400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoverySummary_606411 = ref object of OpenApiRestCall_605589
proc url_GetDiscoverySummary_606413(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoverySummary_606412(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606414 = header.getOrDefault("X-Amz-Target")
  valid_606414 = validateParameter(valid_606414, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.GetDiscoverySummary"))
  if valid_606414 != nil:
    section.add "X-Amz-Target", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Signature")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Signature", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Content-Sha256", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Date")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Date", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Credential")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Credential", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Security-Token")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Security-Token", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Algorithm")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Algorithm", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-SignedHeaders", valid_606421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606423: Call_GetDiscoverySummary_606411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  let valid = call_606423.validator(path, query, header, formData, body)
  let scheme = call_606423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606423.url(scheme.get, call_606423.host, call_606423.base,
                         call_606423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606423, url, valid)

proc call*(call_606424: Call_GetDiscoverySummary_606411; body: JsonNode): Recallable =
  ## getDiscoverySummary
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ##   body: JObject (required)
  var body_606425 = newJObject()
  if body != nil:
    body_606425 = body
  result = call_606424.call(nil, nil, nil, nil, body_606425)

var getDiscoverySummary* = Call_GetDiscoverySummary_606411(
    name: "getDiscoverySummary", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.GetDiscoverySummary",
    validator: validate_GetDiscoverySummary_606412, base: "/",
    url: url_GetDiscoverySummary_606413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_606426 = ref object of OpenApiRestCall_605589
proc url_ListConfigurations_606428(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_606427(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves a list of configuration items as specified by the value passed to the required paramater <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606429 = header.getOrDefault("X-Amz-Target")
  valid_606429 = validateParameter(valid_606429, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListConfigurations"))
  if valid_606429 != nil:
    section.add "X-Amz-Target", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Signature")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Signature", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Content-Sha256", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Date")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Date", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Credential")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Credential", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Security-Token")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Security-Token", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Algorithm")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Algorithm", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-SignedHeaders", valid_606436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606438: Call_ListConfigurations_606426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of configuration items as specified by the value passed to the required paramater <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  let valid = call_606438.validator(path, query, header, formData, body)
  let scheme = call_606438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606438.url(scheme.get, call_606438.host, call_606438.base,
                         call_606438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606438, url, valid)

proc call*(call_606439: Call_ListConfigurations_606426; body: JsonNode): Recallable =
  ## listConfigurations
  ## Retrieves a list of configuration items as specified by the value passed to the required paramater <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ##   body: JObject (required)
  var body_606440 = newJObject()
  if body != nil:
    body_606440 = body
  result = call_606439.call(nil, nil, nil, nil, body_606440)

var listConfigurations* = Call_ListConfigurations_606426(
    name: "listConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListConfigurations",
    validator: validate_ListConfigurations_606427, base: "/",
    url: url_ListConfigurations_606428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServerNeighbors_606441 = ref object of OpenApiRestCall_605589
proc url_ListServerNeighbors_606443(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServerNeighbors_606442(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606444 = header.getOrDefault("X-Amz-Target")
  valid_606444 = validateParameter(valid_606444, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListServerNeighbors"))
  if valid_606444 != nil:
    section.add "X-Amz-Target", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606453: Call_ListServerNeighbors_606441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  let valid = call_606453.validator(path, query, header, formData, body)
  let scheme = call_606453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606453.url(scheme.get, call_606453.host, call_606453.base,
                         call_606453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606453, url, valid)

proc call*(call_606454: Call_ListServerNeighbors_606441; body: JsonNode): Recallable =
  ## listServerNeighbors
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ##   body: JObject (required)
  var body_606455 = newJObject()
  if body != nil:
    body_606455 = body
  result = call_606454.call(nil, nil, nil, nil, body_606455)

var listServerNeighbors* = Call_ListServerNeighbors_606441(
    name: "listServerNeighbors", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListServerNeighbors",
    validator: validate_ListServerNeighbors_606442, base: "/",
    url: url_ListServerNeighbors_606443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContinuousExport_606456 = ref object of OpenApiRestCall_605589
proc url_StartContinuousExport_606458(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartContinuousExport_606457(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606459 = header.getOrDefault("X-Amz-Target")
  valid_606459 = validateParameter(valid_606459, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartContinuousExport"))
  if valid_606459 != nil:
    section.add "X-Amz-Target", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Signature")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Signature", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Content-Sha256", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Date")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Date", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Credential")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Credential", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Security-Token")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Security-Token", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Algorithm")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Algorithm", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-SignedHeaders", valid_606466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606468: Call_StartContinuousExport_606456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_606468.validator(path, query, header, formData, body)
  let scheme = call_606468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606468.url(scheme.get, call_606468.host, call_606468.base,
                         call_606468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606468, url, valid)

proc call*(call_606469: Call_StartContinuousExport_606456; body: JsonNode): Recallable =
  ## startContinuousExport
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_606470 = newJObject()
  if body != nil:
    body_606470 = body
  result = call_606469.call(nil, nil, nil, nil, body_606470)

var startContinuousExport* = Call_StartContinuousExport_606456(
    name: "startContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartContinuousExport",
    validator: validate_StartContinuousExport_606457, base: "/",
    url: url_StartContinuousExport_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDataCollectionByAgentIds_606471 = ref object of OpenApiRestCall_605589
proc url_StartDataCollectionByAgentIds_606473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDataCollectionByAgentIds_606472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606474 = header.getOrDefault("X-Amz-Target")
  valid_606474 = validateParameter(valid_606474, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds"))
  if valid_606474 != nil:
    section.add "X-Amz-Target", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Signature")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Signature", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Content-Sha256", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Date")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Date", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Credential")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Credential", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Security-Token")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Security-Token", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Algorithm")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Algorithm", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-SignedHeaders", valid_606481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606483: Call_StartDataCollectionByAgentIds_606471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  let valid = call_606483.validator(path, query, header, formData, body)
  let scheme = call_606483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606483.url(scheme.get, call_606483.host, call_606483.base,
                         call_606483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606483, url, valid)

proc call*(call_606484: Call_StartDataCollectionByAgentIds_606471; body: JsonNode): Recallable =
  ## startDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to start collecting data.
  ##   body: JObject (required)
  var body_606485 = newJObject()
  if body != nil:
    body_606485 = body
  result = call_606484.call(nil, nil, nil, nil, body_606485)

var startDataCollectionByAgentIds* = Call_StartDataCollectionByAgentIds_606471(
    name: "startDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds",
    validator: validate_StartDataCollectionByAgentIds_606472, base: "/",
    url: url_StartDataCollectionByAgentIds_606473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportTask_606486 = ref object of OpenApiRestCall_605589
proc url_StartExportTask_606488(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportTask_606487(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606489 = header.getOrDefault("X-Amz-Target")
  valid_606489 = validateParameter(valid_606489, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartExportTask"))
  if valid_606489 != nil:
    section.add "X-Amz-Target", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Signature")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Signature", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Content-Sha256", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Date")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Date", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Credential")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Credential", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Security-Token")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Security-Token", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Algorithm")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Algorithm", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-SignedHeaders", valid_606496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606498: Call_StartExportTask_606486; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  let valid = call_606498.validator(path, query, header, formData, body)
  let scheme = call_606498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606498.url(scheme.get, call_606498.host, call_606498.base,
                         call_606498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606498, url, valid)

proc call*(call_606499: Call_StartExportTask_606486; body: JsonNode): Recallable =
  ## startExportTask
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ##   body: JObject (required)
  var body_606500 = newJObject()
  if body != nil:
    body_606500 = body
  result = call_606499.call(nil, nil, nil, nil, body_606500)

var startExportTask* = Call_StartExportTask_606486(name: "startExportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartExportTask",
    validator: validate_StartExportTask_606487, base: "/", url: url_StartExportTask_606488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportTask_606501 = ref object of OpenApiRestCall_605589
proc url_StartImportTask_606503(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportTask_606502(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606504 = header.getOrDefault("X-Amz-Target")
  valid_606504 = validateParameter(valid_606504, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartImportTask"))
  if valid_606504 != nil:
    section.add "X-Amz-Target", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Signature")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Signature", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Content-Sha256", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Date")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Date", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Credential")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Credential", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Security-Token")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Security-Token", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Algorithm")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Algorithm", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-SignedHeaders", valid_606511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606513: Call_StartImportTask_606501; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  let valid = call_606513.validator(path, query, header, formData, body)
  let scheme = call_606513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606513.url(scheme.get, call_606513.host, call_606513.base,
                         call_606513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606513, url, valid)

proc call*(call_606514: Call_StartImportTask_606501; body: JsonNode): Recallable =
  ## startImportTask
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_606515 = newJObject()
  if body != nil:
    body_606515 = body
  result = call_606514.call(nil, nil, nil, nil, body_606515)

var startImportTask* = Call_StartImportTask_606501(name: "startImportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartImportTask",
    validator: validate_StartImportTask_606502, base: "/", url: url_StartImportTask_606503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContinuousExport_606516 = ref object of OpenApiRestCall_605589
proc url_StopContinuousExport_606518(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopContinuousExport_606517(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606519 = header.getOrDefault("X-Amz-Target")
  valid_606519 = validateParameter(valid_606519, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopContinuousExport"))
  if valid_606519 != nil:
    section.add "X-Amz-Target", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Signature")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Signature", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Content-Sha256", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Date")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Date", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Credential")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Credential", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Security-Token")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Security-Token", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Algorithm")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Algorithm", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-SignedHeaders", valid_606526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606528: Call_StopContinuousExport_606516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_606528.validator(path, query, header, formData, body)
  let scheme = call_606528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606528.url(scheme.get, call_606528.host, call_606528.base,
                         call_606528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606528, url, valid)

proc call*(call_606529: Call_StopContinuousExport_606516; body: JsonNode): Recallable =
  ## stopContinuousExport
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_606530 = newJObject()
  if body != nil:
    body_606530 = body
  result = call_606529.call(nil, nil, nil, nil, body_606530)

var stopContinuousExport* = Call_StopContinuousExport_606516(
    name: "stopContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopContinuousExport",
    validator: validate_StopContinuousExport_606517, base: "/",
    url: url_StopContinuousExport_606518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDataCollectionByAgentIds_606531 = ref object of OpenApiRestCall_605589
proc url_StopDataCollectionByAgentIds_606533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDataCollectionByAgentIds_606532(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606534 = header.getOrDefault("X-Amz-Target")
  valid_606534 = validateParameter(valid_606534, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds"))
  if valid_606534 != nil:
    section.add "X-Amz-Target", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Signature")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Signature", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Content-Sha256", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-Date")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-Date", valid_606537
  var valid_606538 = header.getOrDefault("X-Amz-Credential")
  valid_606538 = validateParameter(valid_606538, JString, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "X-Amz-Credential", valid_606538
  var valid_606539 = header.getOrDefault("X-Amz-Security-Token")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Security-Token", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Algorithm")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Algorithm", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-SignedHeaders", valid_606541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606543: Call_StopDataCollectionByAgentIds_606531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  let valid = call_606543.validator(path, query, header, formData, body)
  let scheme = call_606543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606543.url(scheme.get, call_606543.host, call_606543.base,
                         call_606543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606543, url, valid)

proc call*(call_606544: Call_StopDataCollectionByAgentIds_606531; body: JsonNode): Recallable =
  ## stopDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to stop collecting data.
  ##   body: JObject (required)
  var body_606545 = newJObject()
  if body != nil:
    body_606545 = body
  result = call_606544.call(nil, nil, nil, nil, body_606545)

var stopDataCollectionByAgentIds* = Call_StopDataCollectionByAgentIds_606531(
    name: "stopDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds",
    validator: validate_StopDataCollectionByAgentIds_606532, base: "/",
    url: url_StopDataCollectionByAgentIds_606533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_606546 = ref object of OpenApiRestCall_605589
proc url_UpdateApplication_606548(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_606547(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates metadata about an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606549 = header.getOrDefault("X-Amz-Target")
  valid_606549 = validateParameter(valid_606549, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.UpdateApplication"))
  if valid_606549 != nil:
    section.add "X-Amz-Target", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Signature")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Signature", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Content-Sha256", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Date")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Date", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-Credential")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Credential", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Security-Token")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Security-Token", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Algorithm")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Algorithm", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-SignedHeaders", valid_606556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606558: Call_UpdateApplication_606546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates metadata about an application.
  ## 
  let valid = call_606558.validator(path, query, header, formData, body)
  let scheme = call_606558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606558.url(scheme.get, call_606558.host, call_606558.base,
                         call_606558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606558, url, valid)

proc call*(call_606559: Call_UpdateApplication_606546; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates metadata about an application.
  ##   body: JObject (required)
  var body_606560 = newJObject()
  if body != nil:
    body_606560 = body
  result = call_606559.call(nil, nil, nil, nil, body_606560)

var updateApplication* = Call_UpdateApplication_606546(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.UpdateApplication",
    validator: validate_UpdateApplication_606547, base: "/",
    url: url_UpdateApplication_606548, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
