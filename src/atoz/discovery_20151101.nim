
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
## <fullname>AWS Application Discovery Service</fullname> <p>AWS Application Discovery Service helps you plan application migration projects. It automatically identifies servers, virtual machines (VMs), and network dependencies in your on-premises data centers. For more information, see the <a href="http://aws.amazon.com/application-discovery/faqs/">AWS Application Discovery Service FAQ</a>. Application Discovery Service offers three ways of performing discovery and collecting data about your on-premises servers:</p> <ul> <li> <p> <b>Agentless discovery</b> is recommended for environments that use VMware vCenter Server. This mode doesn't require you to install an agent on each host. It does not work in non-VMware environments.</p> <ul> <li> <p>Agentless discovery gathers server information regardless of the operating systems, which minimizes the time required for initial on-premises infrastructure assessment.</p> </li> <li> <p>Agentless discovery doesn't collect information about network dependencies, only agent-based discovery collects that information.</p> </li> </ul> </li> </ul> <ul> <li> <p> <b>Agent-based discovery</b> collects a richer set of data than agentless discovery by using the AWS Application Discovery Agent, which you install on one or more hosts in your data center.</p> <ul> <li> <p> The agent captures infrastructure and application information, including an inventory of running processes, system performance information, resource utilization, and network dependencies.</p> </li> <li> <p>The information collected by agents is secured at rest and in transit to the Application Discovery Service database in the cloud. </p> </li> </ul> </li> </ul> <ul> <li> <p> <b>AWS Partner Network (APN) solutions</b> integrate with Application Discovery Service, enabling you to import details of your on-premises environment directly into Migration Hub without using the discovery connector or discovery agent.</p> <ul> <li> <p>Third-party application discovery tools can query AWS Application Discovery Service, and they can write to the Application Discovery Service database using the public API.</p> </li> <li> <p>In this way, you can import data into Migration Hub and view it, so that you can associate applications with servers and track migrations.</p> </li> </ul> </li> </ul> <p> <b>Recommendations</b> </p> <p>We recommend that you use agent-based discovery for non-VMware environments, and whenever you want to collect information about network dependencies. You can run agent-based and agentless discovery simultaneously. Use agentless discovery to complete the initial infrastructure assessment quickly, and then install agents on select hosts to collect additional information.</p> <p> <b>Working With This Guide</b> </p> <p>This API reference provides descriptions, syntax, and usage examples for each of the actions and data types for Application Discovery Service. The topic for each action shows the API request parameters and the response. Alternatively, you can use one of the AWS SDKs to access an API that is tailored to the programming language or platform that you're using. For more information, see <a href="http://aws.amazon.com/tools/#SDKs">AWS SDKs</a>.</p> <note> <ul> <li> <p>Remember that you must set your Migration Hub home region before you call any of these APIs.</p> </li> <li> <p>You must make API calls for write actions (create, notify, associate, disassociate, import, or put) while in your home region, or a <code>HomeRegionNotSetException</code> error is returned.</p> </li> <li> <p>API calls for read actions (list, describe, stop, and delete) are permitted outside of your home region.</p> </li> <li> <p>Although it is unlikely, the Migration Hub home region could change. If you call APIs outside the home region, an <code>InvalidInputException</code> is returned.</p> </li> <li> <p>You must call <code>GetHomeRegion</code> to obtain the latest Migration Hub home region.</p> </li> </ul> </note> <p>This guide is intended for use with the <a href="http://docs.aws.amazon.com/application-discovery/latest/userguide/">AWS Application Discovery Service User Guide</a>.</p> <important> <p>All data is handled according to the <a href="http://aws.amazon.com/privacy/">AWS Privacy Policy</a>. You can operate Application Discovery Service offline to inspect collected data before it is shared with the service.</p> </important>
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_AssociateConfigurationItemsToApplication_610996 = ref object of OpenApiRestCall_610658
proc url_AssociateConfigurationItemsToApplication_610998(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateConfigurationItemsToApplication_610997(path: JsonNode;
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_AssociateConfigurationItemsToApplication_610996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associates one or more configuration items with an application.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_AssociateConfigurationItemsToApplication_610996;
          body: JsonNode): Recallable =
  ## associateConfigurationItemsToApplication
  ## Associates one or more configuration items with an application.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var associateConfigurationItemsToApplication* = Call_AssociateConfigurationItemsToApplication_610996(
    name: "associateConfigurationItemsToApplication", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication",
    validator: validate_AssociateConfigurationItemsToApplication_610997,
    base: "/", url: url_AssociateConfigurationItemsToApplication_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImportData_611265 = ref object of OpenApiRestCall_610658
proc url_BatchDeleteImportData_611267(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteImportData_611266(path: JsonNode; query: JsonNode;
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.BatchDeleteImportData"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_BatchDeleteImportData_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_BatchDeleteImportData_611265; body: JsonNode): Recallable =
  ## batchDeleteImportData
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var batchDeleteImportData* = Call_BatchDeleteImportData_611265(
    name: "batchDeleteImportData", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.BatchDeleteImportData",
    validator: validate_BatchDeleteImportData_611266, base: "/",
    url: url_BatchDeleteImportData_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_611280 = ref object of OpenApiRestCall_610658
proc url_CreateApplication_611282(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_611281(path: JsonNode; query: JsonNode;
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateApplication"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_CreateApplication_611280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application with the given name and description.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_CreateApplication_611280; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application with the given name and description.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var createApplication* = Call_CreateApplication_611280(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateApplication",
    validator: validate_CreateApplication_611281, base: "/",
    url: url_CreateApplication_611282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_611295 = ref object of OpenApiRestCall_610658
proc url_CreateTags_611297(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTags_611296(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateTags"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_CreateTags_611295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_CreateTags_611295; body: JsonNode): Recallable =
  ## createTags
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var createTags* = Call_CreateTags_611295(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateTags",
                                      validator: validate_CreateTags_611296,
                                      base: "/", url: url_CreateTags_611297,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplications_611310 = ref object of OpenApiRestCall_610658
proc url_DeleteApplications_611312(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplications_611311(path: JsonNode; query: JsonNode;
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
  var valid_611313 = header.getOrDefault("X-Amz-Target")
  valid_611313 = validateParameter(valid_611313, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteApplications"))
  if valid_611313 != nil:
    section.add "X-Amz-Target", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Signature")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Signature", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Content-Sha256", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Date")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Date", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Credential")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Credential", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Security-Token")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Security-Token", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Algorithm")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Algorithm", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-SignedHeaders", valid_611320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611322: Call_DeleteApplications_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  let valid = call_611322.validator(path, query, header, formData, body)
  let scheme = call_611322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611322.url(scheme.get, call_611322.host, call_611322.base,
                         call_611322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611322, url, valid)

proc call*(call_611323: Call_DeleteApplications_611310; body: JsonNode): Recallable =
  ## deleteApplications
  ## Deletes a list of applications and their associations with configuration items.
  ##   body: JObject (required)
  var body_611324 = newJObject()
  if body != nil:
    body_611324 = body
  result = call_611323.call(nil, nil, nil, nil, body_611324)

var deleteApplications* = Call_DeleteApplications_611310(
    name: "deleteApplications", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteApplications",
    validator: validate_DeleteApplications_611311, base: "/",
    url: url_DeleteApplications_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_611325 = ref object of OpenApiRestCall_610658
proc url_DeleteTags_611327(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_611326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611328 = header.getOrDefault("X-Amz-Target")
  valid_611328 = validateParameter(valid_611328, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteTags"))
  if valid_611328 != nil:
    section.add "X-Amz-Target", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Signature")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Signature", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Content-Sha256", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Date")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Date", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Credential")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Credential", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Security-Token")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Security-Token", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Algorithm")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Algorithm", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-SignedHeaders", valid_611335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_DeleteTags_611325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_DeleteTags_611325; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_611339 = newJObject()
  if body != nil:
    body_611339 = body
  result = call_611338.call(nil, nil, nil, nil, body_611339)

var deleteTags* = Call_DeleteTags_611325(name: "deleteTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteTags",
                                      validator: validate_DeleteTags_611326,
                                      base: "/", url: url_DeleteTags_611327,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgents_611340 = ref object of OpenApiRestCall_610658
proc url_DescribeAgents_611342(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAgents_611341(path: JsonNode; query: JsonNode;
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
  var valid_611343 = header.getOrDefault("X-Amz-Target")
  valid_611343 = validateParameter(valid_611343, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeAgents"))
  if valid_611343 != nil:
    section.add "X-Amz-Target", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Signature")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Signature", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Content-Sha256", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Date")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Date", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Credential")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Credential", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Security-Token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Security-Token", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Algorithm")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Algorithm", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-SignedHeaders", valid_611350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611352: Call_DescribeAgents_611340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  let valid = call_611352.validator(path, query, header, formData, body)
  let scheme = call_611352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611352.url(scheme.get, call_611352.host, call_611352.base,
                         call_611352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611352, url, valid)

proc call*(call_611353: Call_DescribeAgents_611340; body: JsonNode): Recallable =
  ## describeAgents
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ##   body: JObject (required)
  var body_611354 = newJObject()
  if body != nil:
    body_611354 = body
  result = call_611353.call(nil, nil, nil, nil, body_611354)

var describeAgents* = Call_DescribeAgents_611340(name: "describeAgents",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeAgents",
    validator: validate_DescribeAgents_611341, base: "/", url: url_DescribeAgents_611342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurations_611355 = ref object of OpenApiRestCall_610658
proc url_DescribeConfigurations_611357(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurations_611356(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
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
  var valid_611358 = header.getOrDefault("X-Amz-Target")
  valid_611358 = validateParameter(valid_611358, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeConfigurations"))
  if valid_611358 != nil:
    section.add "X-Amz-Target", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Signature")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Signature", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Content-Sha256", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Date")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Date", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Credential")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Credential", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Security-Token")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Security-Token", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-Algorithm")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-Algorithm", valid_611364
  var valid_611365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-SignedHeaders", valid_611365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611367: Call_DescribeConfigurations_611355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  let valid = call_611367.validator(path, query, header, formData, body)
  let scheme = call_611367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611367.url(scheme.get, call_611367.host, call_611367.base,
                         call_611367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611367, url, valid)

proc call*(call_611368: Call_DescribeConfigurations_611355; body: JsonNode): Recallable =
  ## describeConfigurations
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_611369 = newJObject()
  if body != nil:
    body_611369 = body
  result = call_611368.call(nil, nil, nil, nil, body_611369)

var describeConfigurations* = Call_DescribeConfigurations_611355(
    name: "describeConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeConfigurations",
    validator: validate_DescribeConfigurations_611356, base: "/",
    url: url_DescribeConfigurations_611357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousExports_611370 = ref object of OpenApiRestCall_610658
proc url_DescribeContinuousExports_611372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeContinuousExports_611371(path: JsonNode; query: JsonNode;
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
  var valid_611373 = query.getOrDefault("nextToken")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "nextToken", valid_611373
  var valid_611374 = query.getOrDefault("maxResults")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "maxResults", valid_611374
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
  var valid_611375 = header.getOrDefault("X-Amz-Target")
  valid_611375 = validateParameter(valid_611375, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeContinuousExports"))
  if valid_611375 != nil:
    section.add "X-Amz-Target", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Signature")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Signature", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Content-Sha256", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Date")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Date", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Credential")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Credential", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Security-Token")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Security-Token", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Algorithm")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Algorithm", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-SignedHeaders", valid_611382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611384: Call_DescribeContinuousExports_611370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  let valid = call_611384.validator(path, query, header, formData, body)
  let scheme = call_611384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611384.url(scheme.get, call_611384.host, call_611384.base,
                         call_611384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611384, url, valid)

proc call*(call_611385: Call_DescribeContinuousExports_611370; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeContinuousExports
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611386 = newJObject()
  var body_611387 = newJObject()
  add(query_611386, "nextToken", newJString(nextToken))
  if body != nil:
    body_611387 = body
  add(query_611386, "maxResults", newJString(maxResults))
  result = call_611385.call(nil, query_611386, nil, nil, body_611387)

var describeContinuousExports* = Call_DescribeContinuousExports_611370(
    name: "describeContinuousExports", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeContinuousExports",
    validator: validate_DescribeContinuousExports_611371, base: "/",
    url: url_DescribeContinuousExports_611372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportConfigurations_611389 = ref object of OpenApiRestCall_610658
proc url_DescribeExportConfigurations_611391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportConfigurations_611390(path: JsonNode; query: JsonNode;
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
  var valid_611392 = header.getOrDefault("X-Amz-Target")
  valid_611392 = validateParameter(valid_611392, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportConfigurations"))
  if valid_611392 != nil:
    section.add "X-Amz-Target", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Signature")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Signature", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Content-Sha256", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Date")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Date", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Credential")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Credential", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Security-Token")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Security-Token", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Algorithm")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Algorithm", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-SignedHeaders", valid_611399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611401: Call_DescribeExportConfigurations_611389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  let valid = call_611401.validator(path, query, header, formData, body)
  let scheme = call_611401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611401.url(scheme.get, call_611401.host, call_611401.base,
                         call_611401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611401, url, valid)

proc call*(call_611402: Call_DescribeExportConfigurations_611389; body: JsonNode): Recallable =
  ## describeExportConfigurations
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ##   body: JObject (required)
  var body_611403 = newJObject()
  if body != nil:
    body_611403 = body
  result = call_611402.call(nil, nil, nil, nil, body_611403)

var describeExportConfigurations* = Call_DescribeExportConfigurations_611389(
    name: "describeExportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportConfigurations",
    validator: validate_DescribeExportConfigurations_611390, base: "/",
    url: url_DescribeExportConfigurations_611391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_611404 = ref object of OpenApiRestCall_610658
proc url_DescribeExportTasks_611406(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportTasks_611405(path: JsonNode; query: JsonNode;
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
  var valid_611407 = header.getOrDefault("X-Amz-Target")
  valid_611407 = validateParameter(valid_611407, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportTasks"))
  if valid_611407 != nil:
    section.add "X-Amz-Target", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611416: Call_DescribeExportTasks_611404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  let valid = call_611416.validator(path, query, header, formData, body)
  let scheme = call_611416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611416.url(scheme.get, call_611416.host, call_611416.base,
                         call_611416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611416, url, valid)

proc call*(call_611417: Call_DescribeExportTasks_611404; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ##   body: JObject (required)
  var body_611418 = newJObject()
  if body != nil:
    body_611418 = body
  result = call_611417.call(nil, nil, nil, nil, body_611418)

var describeExportTasks* = Call_DescribeExportTasks_611404(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportTasks",
    validator: validate_DescribeExportTasks_611405, base: "/",
    url: url_DescribeExportTasks_611406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImportTasks_611419 = ref object of OpenApiRestCall_610658
proc url_DescribeImportTasks_611421(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImportTasks_611420(path: JsonNode; query: JsonNode;
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
  var valid_611422 = query.getOrDefault("nextToken")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "nextToken", valid_611422
  var valid_611423 = query.getOrDefault("maxResults")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "maxResults", valid_611423
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
  var valid_611424 = header.getOrDefault("X-Amz-Target")
  valid_611424 = validateParameter(valid_611424, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeImportTasks"))
  if valid_611424 != nil:
    section.add "X-Amz-Target", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Signature")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Signature", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Content-Sha256", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Date")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Date", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Credential")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Credential", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Security-Token")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Security-Token", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Algorithm")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Algorithm", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-SignedHeaders", valid_611431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611433: Call_DescribeImportTasks_611419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  let valid = call_611433.validator(path, query, header, formData, body)
  let scheme = call_611433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611433.url(scheme.get, call_611433.host, call_611433.base,
                         call_611433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611433, url, valid)

proc call*(call_611434: Call_DescribeImportTasks_611419; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImportTasks
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611435 = newJObject()
  var body_611436 = newJObject()
  add(query_611435, "nextToken", newJString(nextToken))
  if body != nil:
    body_611436 = body
  add(query_611435, "maxResults", newJString(maxResults))
  result = call_611434.call(nil, query_611435, nil, nil, body_611436)

var describeImportTasks* = Call_DescribeImportTasks_611419(
    name: "describeImportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeImportTasks",
    validator: validate_DescribeImportTasks_611420, base: "/",
    url: url_DescribeImportTasks_611421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_611437 = ref object of OpenApiRestCall_610658
proc url_DescribeTags_611439(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_611438(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611440 = header.getOrDefault("X-Amz-Target")
  valid_611440 = validateParameter(valid_611440, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeTags"))
  if valid_611440 != nil:
    section.add "X-Amz-Target", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Signature")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Signature", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Content-Sha256", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Date")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Date", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Credential")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Credential", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Security-Token")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Security-Token", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Algorithm")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Algorithm", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-SignedHeaders", valid_611447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611449: Call_DescribeTags_611437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  let valid = call_611449.validator(path, query, header, formData, body)
  let scheme = call_611449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611449.url(scheme.get, call_611449.host, call_611449.base,
                         call_611449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611449, url, valid)

proc call*(call_611450: Call_DescribeTags_611437; body: JsonNode): Recallable =
  ## describeTags
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ##   body: JObject (required)
  var body_611451 = newJObject()
  if body != nil:
    body_611451 = body
  result = call_611450.call(nil, nil, nil, nil, body_611451)

var describeTags* = Call_DescribeTags_611437(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeTags",
    validator: validate_DescribeTags_611438, base: "/", url: url_DescribeTags_611439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConfigurationItemsFromApplication_611452 = ref object of OpenApiRestCall_610658
proc url_DisassociateConfigurationItemsFromApplication_611454(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConfigurationItemsFromApplication_611453(
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
  var valid_611455 = header.getOrDefault("X-Amz-Target")
  valid_611455 = validateParameter(valid_611455, JString, required = true, default = newJString("AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication"))
  if valid_611455 != nil:
    section.add "X-Amz-Target", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Signature")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Signature", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Content-Sha256", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Date")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Date", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Credential")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Credential", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Security-Token")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Security-Token", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Algorithm")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Algorithm", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-SignedHeaders", valid_611462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611464: Call_DisassociateConfigurationItemsFromApplication_611452;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disassociates one or more configuration items from an application.
  ## 
  let valid = call_611464.validator(path, query, header, formData, body)
  let scheme = call_611464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611464.url(scheme.get, call_611464.host, call_611464.base,
                         call_611464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611464, url, valid)

proc call*(call_611465: Call_DisassociateConfigurationItemsFromApplication_611452;
          body: JsonNode): Recallable =
  ## disassociateConfigurationItemsFromApplication
  ## Disassociates one or more configuration items from an application.
  ##   body: JObject (required)
  var body_611466 = newJObject()
  if body != nil:
    body_611466 = body
  result = call_611465.call(nil, nil, nil, nil, body_611466)

var disassociateConfigurationItemsFromApplication* = Call_DisassociateConfigurationItemsFromApplication_611452(
    name: "disassociateConfigurationItemsFromApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication",
    validator: validate_DisassociateConfigurationItemsFromApplication_611453,
    base: "/", url: url_DisassociateConfigurationItemsFromApplication_611454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportConfigurations_611467 = ref object of OpenApiRestCall_610658
proc url_ExportConfigurations_611469(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportConfigurations_611468(path: JsonNode; query: JsonNode;
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
  var valid_611470 = header.getOrDefault("X-Amz-Target")
  valid_611470 = validateParameter(valid_611470, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ExportConfigurations"))
  if valid_611470 != nil:
    section.add "X-Amz-Target", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Signature")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Signature", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Content-Sha256", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Date")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Date", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Credential")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Credential", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Security-Token")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Security-Token", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Algorithm")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Algorithm", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-SignedHeaders", valid_611477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611478: Call_ExportConfigurations_611467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  let valid = call_611478.validator(path, query, header, formData, body)
  let scheme = call_611478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611478.url(scheme.get, call_611478.host, call_611478.base,
                         call_611478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611478, url, valid)

proc call*(call_611479: Call_ExportConfigurations_611467): Recallable =
  ## exportConfigurations
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  result = call_611479.call(nil, nil, nil, nil, nil)

var exportConfigurations* = Call_ExportConfigurations_611467(
    name: "exportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ExportConfigurations",
    validator: validate_ExportConfigurations_611468, base: "/",
    url: url_ExportConfigurations_611469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoverySummary_611480 = ref object of OpenApiRestCall_610658
proc url_GetDiscoverySummary_611482(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoverySummary_611481(path: JsonNode; query: JsonNode;
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
  var valid_611483 = header.getOrDefault("X-Amz-Target")
  valid_611483 = validateParameter(valid_611483, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.GetDiscoverySummary"))
  if valid_611483 != nil:
    section.add "X-Amz-Target", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Signature")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Signature", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Content-Sha256", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Date")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Date", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Credential")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Credential", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Security-Token")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Security-Token", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Algorithm")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Algorithm", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-SignedHeaders", valid_611490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611492: Call_GetDiscoverySummary_611480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  let valid = call_611492.validator(path, query, header, formData, body)
  let scheme = call_611492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611492.url(scheme.get, call_611492.host, call_611492.base,
                         call_611492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611492, url, valid)

proc call*(call_611493: Call_GetDiscoverySummary_611480; body: JsonNode): Recallable =
  ## getDiscoverySummary
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ##   body: JObject (required)
  var body_611494 = newJObject()
  if body != nil:
    body_611494 = body
  result = call_611493.call(nil, nil, nil, nil, body_611494)

var getDiscoverySummary* = Call_GetDiscoverySummary_611480(
    name: "getDiscoverySummary", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.GetDiscoverySummary",
    validator: validate_GetDiscoverySummary_611481, base: "/",
    url: url_GetDiscoverySummary_611482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_611495 = ref object of OpenApiRestCall_610658
proc url_ListConfigurations_611497(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_611496(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves a list of configuration items as specified by the value passed to the required parameter <code>configurationType</code>. Optional filtering may be applied to refine search results.
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
  var valid_611498 = header.getOrDefault("X-Amz-Target")
  valid_611498 = validateParameter(valid_611498, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListConfigurations"))
  if valid_611498 != nil:
    section.add "X-Amz-Target", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Signature")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Signature", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Content-Sha256", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Date")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Date", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Credential")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Credential", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Security-Token")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Security-Token", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Algorithm")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Algorithm", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-SignedHeaders", valid_611505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611507: Call_ListConfigurations_611495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of configuration items as specified by the value passed to the required parameter <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  let valid = call_611507.validator(path, query, header, formData, body)
  let scheme = call_611507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611507.url(scheme.get, call_611507.host, call_611507.base,
                         call_611507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611507, url, valid)

proc call*(call_611508: Call_ListConfigurations_611495; body: JsonNode): Recallable =
  ## listConfigurations
  ## Retrieves a list of configuration items as specified by the value passed to the required parameter <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ##   body: JObject (required)
  var body_611509 = newJObject()
  if body != nil:
    body_611509 = body
  result = call_611508.call(nil, nil, nil, nil, body_611509)

var listConfigurations* = Call_ListConfigurations_611495(
    name: "listConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListConfigurations",
    validator: validate_ListConfigurations_611496, base: "/",
    url: url_ListConfigurations_611497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServerNeighbors_611510 = ref object of OpenApiRestCall_610658
proc url_ListServerNeighbors_611512(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServerNeighbors_611511(path: JsonNode; query: JsonNode;
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
  var valid_611513 = header.getOrDefault("X-Amz-Target")
  valid_611513 = validateParameter(valid_611513, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListServerNeighbors"))
  if valid_611513 != nil:
    section.add "X-Amz-Target", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Signature")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Signature", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Content-Sha256", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Date")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Date", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Credential")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Credential", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Security-Token")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Security-Token", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Algorithm")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Algorithm", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-SignedHeaders", valid_611520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611522: Call_ListServerNeighbors_611510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  let valid = call_611522.validator(path, query, header, formData, body)
  let scheme = call_611522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611522.url(scheme.get, call_611522.host, call_611522.base,
                         call_611522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611522, url, valid)

proc call*(call_611523: Call_ListServerNeighbors_611510; body: JsonNode): Recallable =
  ## listServerNeighbors
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ##   body: JObject (required)
  var body_611524 = newJObject()
  if body != nil:
    body_611524 = body
  result = call_611523.call(nil, nil, nil, nil, body_611524)

var listServerNeighbors* = Call_ListServerNeighbors_611510(
    name: "listServerNeighbors", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListServerNeighbors",
    validator: validate_ListServerNeighbors_611511, base: "/",
    url: url_ListServerNeighbors_611512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContinuousExport_611525 = ref object of OpenApiRestCall_610658
proc url_StartContinuousExport_611527(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartContinuousExport_611526(path: JsonNode; query: JsonNode;
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
  var valid_611528 = header.getOrDefault("X-Amz-Target")
  valid_611528 = validateParameter(valid_611528, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartContinuousExport"))
  if valid_611528 != nil:
    section.add "X-Amz-Target", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Signature")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Signature", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Content-Sha256", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Date")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Date", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Credential")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Credential", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Security-Token")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Security-Token", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Algorithm")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Algorithm", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-SignedHeaders", valid_611535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611537: Call_StartContinuousExport_611525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_611537.validator(path, query, header, formData, body)
  let scheme = call_611537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611537.url(scheme.get, call_611537.host, call_611537.base,
                         call_611537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611537, url, valid)

proc call*(call_611538: Call_StartContinuousExport_611525; body: JsonNode): Recallable =
  ## startContinuousExport
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_611539 = newJObject()
  if body != nil:
    body_611539 = body
  result = call_611538.call(nil, nil, nil, nil, body_611539)

var startContinuousExport* = Call_StartContinuousExport_611525(
    name: "startContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartContinuousExport",
    validator: validate_StartContinuousExport_611526, base: "/",
    url: url_StartContinuousExport_611527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDataCollectionByAgentIds_611540 = ref object of OpenApiRestCall_610658
proc url_StartDataCollectionByAgentIds_611542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDataCollectionByAgentIds_611541(path: JsonNode; query: JsonNode;
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
  var valid_611543 = header.getOrDefault("X-Amz-Target")
  valid_611543 = validateParameter(valid_611543, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds"))
  if valid_611543 != nil:
    section.add "X-Amz-Target", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Signature")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Signature", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Content-Sha256", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Date")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Date", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Credential")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Credential", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Security-Token")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Security-Token", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Algorithm")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Algorithm", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-SignedHeaders", valid_611550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611552: Call_StartDataCollectionByAgentIds_611540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  let valid = call_611552.validator(path, query, header, formData, body)
  let scheme = call_611552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611552.url(scheme.get, call_611552.host, call_611552.base,
                         call_611552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611552, url, valid)

proc call*(call_611553: Call_StartDataCollectionByAgentIds_611540; body: JsonNode): Recallable =
  ## startDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to start collecting data.
  ##   body: JObject (required)
  var body_611554 = newJObject()
  if body != nil:
    body_611554 = body
  result = call_611553.call(nil, nil, nil, nil, body_611554)

var startDataCollectionByAgentIds* = Call_StartDataCollectionByAgentIds_611540(
    name: "startDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds",
    validator: validate_StartDataCollectionByAgentIds_611541, base: "/",
    url: url_StartDataCollectionByAgentIds_611542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportTask_611555 = ref object of OpenApiRestCall_610658
proc url_StartExportTask_611557(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportTask_611556(path: JsonNode; query: JsonNode;
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
  var valid_611558 = header.getOrDefault("X-Amz-Target")
  valid_611558 = validateParameter(valid_611558, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartExportTask"))
  if valid_611558 != nil:
    section.add "X-Amz-Target", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Signature")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Signature", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Content-Sha256", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Date")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Date", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Credential")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Credential", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Security-Token")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Security-Token", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Algorithm")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Algorithm", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-SignedHeaders", valid_611565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611567: Call_StartExportTask_611555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  let valid = call_611567.validator(path, query, header, formData, body)
  let scheme = call_611567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611567.url(scheme.get, call_611567.host, call_611567.base,
                         call_611567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611567, url, valid)

proc call*(call_611568: Call_StartExportTask_611555; body: JsonNode): Recallable =
  ## startExportTask
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ##   body: JObject (required)
  var body_611569 = newJObject()
  if body != nil:
    body_611569 = body
  result = call_611568.call(nil, nil, nil, nil, body_611569)

var startExportTask* = Call_StartExportTask_611555(name: "startExportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartExportTask",
    validator: validate_StartExportTask_611556, base: "/", url: url_StartExportTask_611557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportTask_611570 = ref object of OpenApiRestCall_610658
proc url_StartImportTask_611572(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportTask_611571(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS Migration Hub without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
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
  var valid_611573 = header.getOrDefault("X-Amz-Target")
  valid_611573 = validateParameter(valid_611573, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartImportTask"))
  if valid_611573 != nil:
    section.add "X-Amz-Target", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Signature")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Signature", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Content-Sha256", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Date")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Date", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Credential")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Credential", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Security-Token")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Security-Token", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Algorithm")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Algorithm", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-SignedHeaders", valid_611580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611582: Call_StartImportTask_611570; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS Migration Hub without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  let valid = call_611582.validator(path, query, header, formData, body)
  let scheme = call_611582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611582.url(scheme.get, call_611582.host, call_611582.base,
                         call_611582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611582, url, valid)

proc call*(call_611583: Call_StartImportTask_611570; body: JsonNode): Recallable =
  ## startImportTask
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS Migration Hub without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_611584 = newJObject()
  if body != nil:
    body_611584 = body
  result = call_611583.call(nil, nil, nil, nil, body_611584)

var startImportTask* = Call_StartImportTask_611570(name: "startImportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartImportTask",
    validator: validate_StartImportTask_611571, base: "/", url: url_StartImportTask_611572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContinuousExport_611585 = ref object of OpenApiRestCall_610658
proc url_StopContinuousExport_611587(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopContinuousExport_611586(path: JsonNode; query: JsonNode;
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
  var valid_611588 = header.getOrDefault("X-Amz-Target")
  valid_611588 = validateParameter(valid_611588, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopContinuousExport"))
  if valid_611588 != nil:
    section.add "X-Amz-Target", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Signature")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Signature", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Content-Sha256", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Date")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Date", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Credential")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Credential", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Security-Token")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Security-Token", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Algorithm")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Algorithm", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-SignedHeaders", valid_611595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611597: Call_StopContinuousExport_611585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_611597.validator(path, query, header, formData, body)
  let scheme = call_611597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611597.url(scheme.get, call_611597.host, call_611597.base,
                         call_611597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611597, url, valid)

proc call*(call_611598: Call_StopContinuousExport_611585; body: JsonNode): Recallable =
  ## stopContinuousExport
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_611599 = newJObject()
  if body != nil:
    body_611599 = body
  result = call_611598.call(nil, nil, nil, nil, body_611599)

var stopContinuousExport* = Call_StopContinuousExport_611585(
    name: "stopContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopContinuousExport",
    validator: validate_StopContinuousExport_611586, base: "/",
    url: url_StopContinuousExport_611587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDataCollectionByAgentIds_611600 = ref object of OpenApiRestCall_610658
proc url_StopDataCollectionByAgentIds_611602(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDataCollectionByAgentIds_611601(path: JsonNode; query: JsonNode;
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
  var valid_611603 = header.getOrDefault("X-Amz-Target")
  valid_611603 = validateParameter(valid_611603, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds"))
  if valid_611603 != nil:
    section.add "X-Amz-Target", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Signature")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Signature", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Content-Sha256", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Date")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Date", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-Credential")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-Credential", valid_611607
  var valid_611608 = header.getOrDefault("X-Amz-Security-Token")
  valid_611608 = validateParameter(valid_611608, JString, required = false,
                                 default = nil)
  if valid_611608 != nil:
    section.add "X-Amz-Security-Token", valid_611608
  var valid_611609 = header.getOrDefault("X-Amz-Algorithm")
  valid_611609 = validateParameter(valid_611609, JString, required = false,
                                 default = nil)
  if valid_611609 != nil:
    section.add "X-Amz-Algorithm", valid_611609
  var valid_611610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-SignedHeaders", valid_611610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611612: Call_StopDataCollectionByAgentIds_611600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  let valid = call_611612.validator(path, query, header, formData, body)
  let scheme = call_611612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611612.url(scheme.get, call_611612.host, call_611612.base,
                         call_611612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611612, url, valid)

proc call*(call_611613: Call_StopDataCollectionByAgentIds_611600; body: JsonNode): Recallable =
  ## stopDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to stop collecting data.
  ##   body: JObject (required)
  var body_611614 = newJObject()
  if body != nil:
    body_611614 = body
  result = call_611613.call(nil, nil, nil, nil, body_611614)

var stopDataCollectionByAgentIds* = Call_StopDataCollectionByAgentIds_611600(
    name: "stopDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds",
    validator: validate_StopDataCollectionByAgentIds_611601, base: "/",
    url: url_StopDataCollectionByAgentIds_611602,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_611615 = ref object of OpenApiRestCall_610658
proc url_UpdateApplication_611617(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_611616(path: JsonNode; query: JsonNode;
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
  var valid_611618 = header.getOrDefault("X-Amz-Target")
  valid_611618 = validateParameter(valid_611618, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.UpdateApplication"))
  if valid_611618 != nil:
    section.add "X-Amz-Target", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Signature")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Signature", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Content-Sha256", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Date")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Date", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-Credential")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Credential", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Security-Token")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Security-Token", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Algorithm")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Algorithm", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-SignedHeaders", valid_611625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611627: Call_UpdateApplication_611615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates metadata about an application.
  ## 
  let valid = call_611627.validator(path, query, header, formData, body)
  let scheme = call_611627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611627.url(scheme.get, call_611627.host, call_611627.base,
                         call_611627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611627, url, valid)

proc call*(call_611628: Call_UpdateApplication_611615; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates metadata about an application.
  ##   body: JObject (required)
  var body_611629 = newJObject()
  if body != nil:
    body_611629 = body
  result = call_611628.call(nil, nil, nil, nil, body_611629)

var updateApplication* = Call_UpdateApplication_611615(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.UpdateApplication",
    validator: validate_UpdateApplication_611616, base: "/",
    url: url_UpdateApplication_611617, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
