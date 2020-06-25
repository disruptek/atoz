
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
    if required:
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateConfigurationItemsToApplication_21625779 = ref object of OpenApiRestCall_21625435
proc url_AssociateConfigurationItemsToApplication_21625781(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateConfigurationItemsToApplication_21625780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associates one or more configuration items with an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625882 = header.getOrDefault("X-Amz-Date")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Date", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Security-Token", valid_21625883
  var valid_21625898 = header.getOrDefault("X-Amz-Target")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication"))
  if valid_21625898 != nil:
    section.add "X-Amz-Target", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625929: Call_AssociateConfigurationItemsToApplication_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates one or more configuration items with an application.
  ## 
  let valid = call_21625929.validator(path, query, header, formData, body, _)
  let scheme = call_21625929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625929.makeUrl(scheme.get, call_21625929.host, call_21625929.base,
                               call_21625929.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625929, uri, valid, _)

proc call*(call_21625992: Call_AssociateConfigurationItemsToApplication_21625779;
          body: JsonNode): Recallable =
  ## associateConfigurationItemsToApplication
  ## Associates one or more configuration items with an application.
  ##   body: JObject (required)
  var body_21625993 = newJObject()
  if body != nil:
    body_21625993 = body
  result = call_21625992.call(nil, nil, nil, nil, body_21625993)

var associateConfigurationItemsToApplication* = Call_AssociateConfigurationItemsToApplication_21625779(
    name: "associateConfigurationItemsToApplication", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.AssociateConfigurationItemsToApplication",
    validator: validate_AssociateConfigurationItemsToApplication_21625780,
    base: "/", makeUrl: url_AssociateConfigurationItemsToApplication_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImportData_21626029 = ref object of OpenApiRestCall_21625435
proc url_BatchDeleteImportData_21626031(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteImportData_21626030(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626032 = header.getOrDefault("X-Amz-Date")
  valid_21626032 = validateParameter(valid_21626032, JString, required = false,
                                   default = nil)
  if valid_21626032 != nil:
    section.add "X-Amz-Date", valid_21626032
  var valid_21626033 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626033 = validateParameter(valid_21626033, JString, required = false,
                                   default = nil)
  if valid_21626033 != nil:
    section.add "X-Amz-Security-Token", valid_21626033
  var valid_21626034 = header.getOrDefault("X-Amz-Target")
  valid_21626034 = validateParameter(valid_21626034, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.BatchDeleteImportData"))
  if valid_21626034 != nil:
    section.add "X-Amz-Target", valid_21626034
  var valid_21626035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626035 = validateParameter(valid_21626035, JString, required = false,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626035
  var valid_21626036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "X-Amz-Algorithm", valid_21626036
  var valid_21626037 = header.getOrDefault("X-Amz-Signature")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Signature", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Credential")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Credential", valid_21626039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626041: Call_BatchDeleteImportData_21626029;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ## 
  let valid = call_21626041.validator(path, query, header, formData, body, _)
  let scheme = call_21626041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626041.makeUrl(scheme.get, call_21626041.host, call_21626041.base,
                               call_21626041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626041, uri, valid, _)

proc call*(call_21626042: Call_BatchDeleteImportData_21626029; body: JsonNode): Recallable =
  ## batchDeleteImportData
  ## <p>Deletes one or more import tasks, each identified by their import ID. Each import task has a number of records that can identify servers or applications. </p> <p>AWS Application Discovery Service has built-in matching logic that will identify when discovered servers match existing entries that you've previously discovered, the information for the already-existing discovered server is updated. When you delete an import task that contains records that were used to match, the information in those matched records that comes from the deleted records will also be deleted.</p>
  ##   body: JObject (required)
  var body_21626043 = newJObject()
  if body != nil:
    body_21626043 = body
  result = call_21626042.call(nil, nil, nil, nil, body_21626043)

var batchDeleteImportData* = Call_BatchDeleteImportData_21626029(
    name: "batchDeleteImportData", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.BatchDeleteImportData",
    validator: validate_BatchDeleteImportData_21626030, base: "/",
    makeUrl: url_BatchDeleteImportData_21626031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_21626044 = ref object of OpenApiRestCall_21625435
proc url_CreateApplication_21626046(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_21626045(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an application with the given name and description.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626047 = header.getOrDefault("X-Amz-Date")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Date", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Security-Token", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Target")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateApplication"))
  if valid_21626049 != nil:
    section.add "X-Amz-Target", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Algorithm", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Signature")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Signature", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Credential")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Credential", valid_21626054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626056: Call_CreateApplication_21626044; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an application with the given name and description.
  ## 
  let valid = call_21626056.validator(path, query, header, formData, body, _)
  let scheme = call_21626056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626056.makeUrl(scheme.get, call_21626056.host, call_21626056.base,
                               call_21626056.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626056, uri, valid, _)

proc call*(call_21626057: Call_CreateApplication_21626044; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application with the given name and description.
  ##   body: JObject (required)
  var body_21626058 = newJObject()
  if body != nil:
    body_21626058 = body
  result = call_21626057.call(nil, nil, nil, nil, body_21626058)

var createApplication* = Call_CreateApplication_21626044(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateApplication",
    validator: validate_CreateApplication_21626045, base: "/",
    makeUrl: url_CreateApplication_21626046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_21626059 = ref object of OpenApiRestCall_21625435
proc url_CreateTags_21626061(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTags_21626060(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626062 = header.getOrDefault("X-Amz-Date")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Date", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Security-Token", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Target")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.CreateTags"))
  if valid_21626064 != nil:
    section.add "X-Amz-Target", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_CreateTags_21626059; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_CreateTags_21626059; body: JsonNode): Recallable =
  ## createTags
  ## Creates one or more tags for configuration items. Tags are metadata that help you categorize IT assets. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_21626073 = newJObject()
  if body != nil:
    body_21626073 = body
  result = call_21626072.call(nil, nil, nil, nil, body_21626073)

var createTags* = Call_CreateTags_21626059(name: "createTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.CreateTags",
                                        validator: validate_CreateTags_21626060,
                                        base: "/", makeUrl: url_CreateTags_21626061,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplications_21626074 = ref object of OpenApiRestCall_21625435
proc url_DeleteApplications_21626076(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplications_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626077 = header.getOrDefault("X-Amz-Date")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Date", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Security-Token", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Target")
  valid_21626079 = validateParameter(valid_21626079, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteApplications"))
  if valid_21626079 != nil:
    section.add "X-Amz-Target", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_DeleteApplications_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a list of applications and their associations with configuration items.
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_DeleteApplications_21626074; body: JsonNode): Recallable =
  ## deleteApplications
  ## Deletes a list of applications and their associations with configuration items.
  ##   body: JObject (required)
  var body_21626088 = newJObject()
  if body != nil:
    body_21626088 = body
  result = call_21626087.call(nil, nil, nil, nil, body_21626088)

var deleteApplications* = Call_DeleteApplications_21626074(
    name: "deleteApplications", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteApplications",
    validator: validate_DeleteApplications_21626075, base: "/",
    makeUrl: url_DeleteApplications_21626076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_21626089 = ref object of OpenApiRestCall_21625435
proc url_DeleteTags_21626091(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTags_21626090(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Target")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DeleteTags"))
  if valid_21626094 != nil:
    section.add "X-Amz-Target", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Algorithm", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Signature")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Signature", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Credential")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Credential", valid_21626099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626101: Call_DeleteTags_21626089; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ## 
  let valid = call_21626101.validator(path, query, header, formData, body, _)
  let scheme = call_21626101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626101.makeUrl(scheme.get, call_21626101.host, call_21626101.base,
                               call_21626101.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626101, uri, valid, _)

proc call*(call_21626102: Call_DeleteTags_21626089; body: JsonNode): Recallable =
  ## deleteTags
  ## Deletes the association between configuration items and one or more tags. This API accepts a list of multiple configuration items.
  ##   body: JObject (required)
  var body_21626103 = newJObject()
  if body != nil:
    body_21626103 = body
  result = call_21626102.call(nil, nil, nil, nil, body_21626103)

var deleteTags* = Call_DeleteTags_21626089(name: "deleteTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DeleteTags",
                                        validator: validate_DeleteTags_21626090,
                                        base: "/", makeUrl: url_DeleteTags_21626091,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgents_21626104 = ref object of OpenApiRestCall_21625435
proc url_DescribeAgents_21626106(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAgents_21626105(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Target")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeAgents"))
  if valid_21626109 != nil:
    section.add "X-Amz-Target", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626116: Call_DescribeAgents_21626104; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_DescribeAgents_21626104; body: JsonNode): Recallable =
  ## describeAgents
  ## Lists agents or connectors as specified by ID or other filters. All agents/connectors associated with your user account can be listed if you call <code>DescribeAgents</code> as is without passing any parameters.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var describeAgents* = Call_DescribeAgents_21626104(name: "describeAgents",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeAgents",
    validator: validate_DescribeAgents_21626105, base: "/",
    makeUrl: url_DescribeAgents_21626106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurations_21626119 = ref object of OpenApiRestCall_21625435
proc url_DescribeConfigurations_21626121(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeConfigurations_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Target")
  valid_21626124 = validateParameter(valid_21626124, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeConfigurations"))
  if valid_21626124 != nil:
    section.add "X-Amz-Target", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Algorithm", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Signature")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Signature", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Credential")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Credential", valid_21626129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_DescribeConfigurations_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_DescribeConfigurations_21626119; body: JsonNode): Recallable =
  ## describeConfigurations
  ## <p>Retrieves attributes for a list of configuration item IDs.</p> <note> <p>All of the supplied IDs must be for the same asset type from one of the following:</p> <ul> <li> <p>server</p> </li> <li> <p>application</p> </li> <li> <p>process</p> </li> <li> <p>connection</p> </li> </ul> <p>Output fields are specific to the asset type specified. For example, the output for a <i>server</i> configuration item includes a list of attributes about the server, such as host name, operating system, number of network cards, etc.</p> <p>For a complete list of outputs for each asset type, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-api-queries.html#DescribeConfigurations">Using the DescribeConfigurations Action</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_21626133 = newJObject()
  if body != nil:
    body_21626133 = body
  result = call_21626132.call(nil, nil, nil, nil, body_21626133)

var describeConfigurations* = Call_DescribeConfigurations_21626119(
    name: "describeConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeConfigurations",
    validator: validate_DescribeConfigurations_21626120, base: "/",
    makeUrl: url_DescribeConfigurations_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContinuousExports_21626134 = ref object of OpenApiRestCall_21625435
proc url_DescribeContinuousExports_21626136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeContinuousExports_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626137 = query.getOrDefault("maxResults")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "maxResults", valid_21626137
  var valid_21626138 = query.getOrDefault("nextToken")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "nextToken", valid_21626138
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Target")
  valid_21626141 = validateParameter(valid_21626141, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeContinuousExports"))
  if valid_21626141 != nil:
    section.add "X-Amz-Target", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626148: Call_DescribeContinuousExports_21626134;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_DescribeContinuousExports_21626134; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeContinuousExports
  ## Lists exports as specified by ID. All continuous exports associated with your user account can be listed if you call <code>DescribeContinuousExports</code> as is without passing any parameters.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626151 = newJObject()
  var body_21626152 = newJObject()
  add(query_21626151, "maxResults", newJString(maxResults))
  add(query_21626151, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626152 = body
  result = call_21626149.call(nil, query_21626151, nil, nil, body_21626152)

var describeContinuousExports* = Call_DescribeContinuousExports_21626134(
    name: "describeContinuousExports", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeContinuousExports",
    validator: validate_DescribeContinuousExports_21626135, base: "/",
    makeUrl: url_DescribeContinuousExports_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportConfigurations_21626156 = ref object of OpenApiRestCall_21625435
proc url_DescribeExportConfigurations_21626158(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportConfigurations_21626157(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626159 = header.getOrDefault("X-Amz-Date")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Date", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Security-Token", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Target")
  valid_21626161 = validateParameter(valid_21626161, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportConfigurations"))
  if valid_21626161 != nil:
    section.add "X-Amz-Target", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Algorithm", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Signature")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Signature", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Credential")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Credential", valid_21626166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626168: Call_DescribeExportConfigurations_21626156;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ## 
  let valid = call_21626168.validator(path, query, header, formData, body, _)
  let scheme = call_21626168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626168.makeUrl(scheme.get, call_21626168.host, call_21626168.base,
                               call_21626168.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626168, uri, valid, _)

proc call*(call_21626169: Call_DescribeExportConfigurations_21626156;
          body: JsonNode): Recallable =
  ## describeExportConfigurations
  ##  <code>DescribeExportConfigurations</code> is deprecated. Use <a href="https://docs.aws.amazon.com/application-discovery/latest/APIReference/API_DescribeExportTasks.html">DescribeImportTasks</a>, instead.
  ##   body: JObject (required)
  var body_21626170 = newJObject()
  if body != nil:
    body_21626170 = body
  result = call_21626169.call(nil, nil, nil, nil, body_21626170)

var describeExportConfigurations* = Call_DescribeExportConfigurations_21626156(
    name: "describeExportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportConfigurations",
    validator: validate_DescribeExportConfigurations_21626157, base: "/",
    makeUrl: url_DescribeExportConfigurations_21626158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeExportTasks_21626171 = ref object of OpenApiRestCall_21625435
proc url_DescribeExportTasks_21626173(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeExportTasks_21626172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626174 = header.getOrDefault("X-Amz-Date")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Date", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Security-Token", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Target")
  valid_21626176 = validateParameter(valid_21626176, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeExportTasks"))
  if valid_21626176 != nil:
    section.add "X-Amz-Target", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Algorithm", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Signature", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Credential")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Credential", valid_21626181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626183: Call_DescribeExportTasks_21626171; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ## 
  let valid = call_21626183.validator(path, query, header, formData, body, _)
  let scheme = call_21626183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626183.makeUrl(scheme.get, call_21626183.host, call_21626183.base,
                               call_21626183.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626183, uri, valid, _)

proc call*(call_21626184: Call_DescribeExportTasks_21626171; body: JsonNode): Recallable =
  ## describeExportTasks
  ## Retrieve status of one or more export tasks. You can retrieve the status of up to 100 export tasks.
  ##   body: JObject (required)
  var body_21626185 = newJObject()
  if body != nil:
    body_21626185 = body
  result = call_21626184.call(nil, nil, nil, nil, body_21626185)

var describeExportTasks* = Call_DescribeExportTasks_21626171(
    name: "describeExportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeExportTasks",
    validator: validate_DescribeExportTasks_21626172, base: "/",
    makeUrl: url_DescribeExportTasks_21626173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImportTasks_21626186 = ref object of OpenApiRestCall_21625435
proc url_DescribeImportTasks_21626188(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImportTasks_21626187(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_21626189 = query.getOrDefault("maxResults")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "maxResults", valid_21626189
  var valid_21626190 = query.getOrDefault("nextToken")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "nextToken", valid_21626190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626191 = header.getOrDefault("X-Amz-Date")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Date", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Security-Token", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Target")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeImportTasks"))
  if valid_21626193 != nil:
    section.add "X-Amz-Target", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Algorithm", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Signature")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Signature", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Credential")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Credential", valid_21626198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626200: Call_DescribeImportTasks_21626186; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ## 
  let valid = call_21626200.validator(path, query, header, formData, body, _)
  let scheme = call_21626200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626200.makeUrl(scheme.get, call_21626200.host, call_21626200.base,
                               call_21626200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626200, uri, valid, _)

proc call*(call_21626201: Call_DescribeImportTasks_21626186; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeImportTasks
  ## Returns an array of import tasks for your account, including status information, times, IDs, the Amazon S3 Object URL for the import file, and more.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_21626202 = newJObject()
  var body_21626203 = newJObject()
  add(query_21626202, "maxResults", newJString(maxResults))
  add(query_21626202, "nextToken", newJString(nextToken))
  if body != nil:
    body_21626203 = body
  result = call_21626201.call(nil, query_21626202, nil, nil, body_21626203)

var describeImportTasks* = Call_DescribeImportTasks_21626186(
    name: "describeImportTasks", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeImportTasks",
    validator: validate_DescribeImportTasks_21626187, base: "/",
    makeUrl: url_DescribeImportTasks_21626188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTags_21626204 = ref object of OpenApiRestCall_21625435
proc url_DescribeTags_21626206(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTags_21626205(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626207 = header.getOrDefault("X-Amz-Date")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Date", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Security-Token", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Target")
  valid_21626209 = validateParameter(valid_21626209, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.DescribeTags"))
  if valid_21626209 != nil:
    section.add "X-Amz-Target", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626216: Call_DescribeTags_21626204; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ## 
  let valid = call_21626216.validator(path, query, header, formData, body, _)
  let scheme = call_21626216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626216.makeUrl(scheme.get, call_21626216.host, call_21626216.base,
                               call_21626216.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626216, uri, valid, _)

proc call*(call_21626217: Call_DescribeTags_21626204; body: JsonNode): Recallable =
  ## describeTags
  ## <p>Retrieves a list of configuration items that have tags as specified by the key-value pairs, name and value, passed to the optional parameter <code>filters</code>.</p> <p>There are three valid tag filter names:</p> <ul> <li> <p>tagKey</p> </li> <li> <p>tagValue</p> </li> <li> <p>configurationId</p> </li> </ul> <p>Also, all configuration items associated with your user account that have tags can be listed if you call <code>DescribeTags</code> as is without passing any parameters.</p>
  ##   body: JObject (required)
  var body_21626218 = newJObject()
  if body != nil:
    body_21626218 = body
  result = call_21626217.call(nil, nil, nil, nil, body_21626218)

var describeTags* = Call_DescribeTags_21626204(name: "describeTags",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DescribeTags",
    validator: validate_DescribeTags_21626205, base: "/", makeUrl: url_DescribeTags_21626206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateConfigurationItemsFromApplication_21626219 = ref object of OpenApiRestCall_21625435
proc url_DisassociateConfigurationItemsFromApplication_21626221(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateConfigurationItemsFromApplication_21626220(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates one or more configuration items from an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626222 = header.getOrDefault("X-Amz-Date")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Date", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Security-Token", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Target")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true, default = newJString("AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication"))
  if valid_21626224 != nil:
    section.add "X-Amz-Target", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Algorithm", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Signature")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Signature", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Credential")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Credential", valid_21626229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626231: Call_DisassociateConfigurationItemsFromApplication_21626219;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates one or more configuration items from an application.
  ## 
  let valid = call_21626231.validator(path, query, header, formData, body, _)
  let scheme = call_21626231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626231.makeUrl(scheme.get, call_21626231.host, call_21626231.base,
                               call_21626231.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626231, uri, valid, _)

proc call*(call_21626232: Call_DisassociateConfigurationItemsFromApplication_21626219;
          body: JsonNode): Recallable =
  ## disassociateConfigurationItemsFromApplication
  ## Disassociates one or more configuration items from an application.
  ##   body: JObject (required)
  var body_21626233 = newJObject()
  if body != nil:
    body_21626233 = body
  result = call_21626232.call(nil, nil, nil, nil, body_21626233)

var disassociateConfigurationItemsFromApplication* = Call_DisassociateConfigurationItemsFromApplication_21626219(
    name: "disassociateConfigurationItemsFromApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.DisassociateConfigurationItemsFromApplication",
    validator: validate_DisassociateConfigurationItemsFromApplication_21626220,
    base: "/", makeUrl: url_DisassociateConfigurationItemsFromApplication_21626221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportConfigurations_21626234 = ref object of OpenApiRestCall_21625435
proc url_ExportConfigurations_21626236(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ExportConfigurations_21626235(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626237 = header.getOrDefault("X-Amz-Date")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Date", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Security-Token", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Target")
  valid_21626239 = validateParameter(valid_21626239, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ExportConfigurations"))
  if valid_21626239 != nil:
    section.add "X-Amz-Target", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Algorithm", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Signature")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Signature", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Credential")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Credential", valid_21626244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626245: Call_ExportConfigurations_21626234; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  ## 
  let valid = call_21626245.validator(path, query, header, formData, body, _)
  let scheme = call_21626245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626245.makeUrl(scheme.get, call_21626245.host, call_21626245.base,
                               call_21626245.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626245, uri, valid, _)

proc call*(call_21626246: Call_ExportConfigurations_21626234): Recallable =
  ## exportConfigurations
  ## <p>Deprecated. Use <code>StartExportTask</code> instead.</p> <p>Exports all discovered configuration data to an Amazon S3 bucket or an application that enables you to view and evaluate the data. Data includes tags and tag associations, processes, connections, servers, and system performance. This API returns an export ID that you can query using the <i>DescribeExportConfigurations</i> API. The system imposes a limit of two configuration exports in six hours.</p>
  result = call_21626246.call(nil, nil, nil, nil, nil)

var exportConfigurations* = Call_ExportConfigurations_21626234(
    name: "exportConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ExportConfigurations",
    validator: validate_ExportConfigurations_21626235, base: "/",
    makeUrl: url_ExportConfigurations_21626236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoverySummary_21626247 = ref object of OpenApiRestCall_21625435
proc url_GetDiscoverySummary_21626249(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDiscoverySummary_21626248(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626250 = header.getOrDefault("X-Amz-Date")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Date", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Security-Token", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Target")
  valid_21626252 = validateParameter(valid_21626252, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.GetDiscoverySummary"))
  if valid_21626252 != nil:
    section.add "X-Amz-Target", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Algorithm", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Signature")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Signature", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Credential")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Credential", valid_21626257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626259: Call_GetDiscoverySummary_21626247; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ## 
  let valid = call_21626259.validator(path, query, header, formData, body, _)
  let scheme = call_21626259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626259.makeUrl(scheme.get, call_21626259.host, call_21626259.base,
                               call_21626259.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626259, uri, valid, _)

proc call*(call_21626260: Call_GetDiscoverySummary_21626247; body: JsonNode): Recallable =
  ## getDiscoverySummary
  ## <p>Retrieves a short summary of discovered assets.</p> <p>This API operation takes no request parameters and is called as is at the command prompt as shown in the example.</p>
  ##   body: JObject (required)
  var body_21626261 = newJObject()
  if body != nil:
    body_21626261 = body
  result = call_21626260.call(nil, nil, nil, nil, body_21626261)

var getDiscoverySummary* = Call_GetDiscoverySummary_21626247(
    name: "getDiscoverySummary", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.GetDiscoverySummary",
    validator: validate_GetDiscoverySummary_21626248, base: "/",
    makeUrl: url_GetDiscoverySummary_21626249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurations_21626262 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurations_21626264(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurations_21626263(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of configuration items as specified by the value passed to the required parameter <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626265 = header.getOrDefault("X-Amz-Date")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Date", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Security-Token", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Target")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListConfigurations"))
  if valid_21626267 != nil:
    section.add "X-Amz-Target", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Algorithm", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Signature")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Signature", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Credential")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Credential", valid_21626272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626274: Call_ListConfigurations_21626262; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of configuration items as specified by the value passed to the required parameter <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ## 
  let valid = call_21626274.validator(path, query, header, formData, body, _)
  let scheme = call_21626274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626274.makeUrl(scheme.get, call_21626274.host, call_21626274.base,
                               call_21626274.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626274, uri, valid, _)

proc call*(call_21626275: Call_ListConfigurations_21626262; body: JsonNode): Recallable =
  ## listConfigurations
  ## Retrieves a list of configuration items as specified by the value passed to the required parameter <code>configurationType</code>. Optional filtering may be applied to refine search results.
  ##   body: JObject (required)
  var body_21626276 = newJObject()
  if body != nil:
    body_21626276 = body
  result = call_21626275.call(nil, nil, nil, nil, body_21626276)

var listConfigurations* = Call_ListConfigurations_21626262(
    name: "listConfigurations", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListConfigurations",
    validator: validate_ListConfigurations_21626263, base: "/",
    makeUrl: url_ListConfigurations_21626264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServerNeighbors_21626277 = ref object of OpenApiRestCall_21625435
proc url_ListServerNeighbors_21626279(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListServerNeighbors_21626278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626280 = header.getOrDefault("X-Amz-Date")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Date", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Security-Token", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Target")
  valid_21626282 = validateParameter(valid_21626282, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.ListServerNeighbors"))
  if valid_21626282 != nil:
    section.add "X-Amz-Target", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Algorithm", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Signature")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Signature", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Credential")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Credential", valid_21626287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626289: Call_ListServerNeighbors_21626277; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ## 
  let valid = call_21626289.validator(path, query, header, formData, body, _)
  let scheme = call_21626289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626289.makeUrl(scheme.get, call_21626289.host, call_21626289.base,
                               call_21626289.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626289, uri, valid, _)

proc call*(call_21626290: Call_ListServerNeighbors_21626277; body: JsonNode): Recallable =
  ## listServerNeighbors
  ## Retrieves a list of servers that are one network hop away from a specified server.
  ##   body: JObject (required)
  var body_21626291 = newJObject()
  if body != nil:
    body_21626291 = body
  result = call_21626290.call(nil, nil, nil, nil, body_21626291)

var listServerNeighbors* = Call_ListServerNeighbors_21626277(
    name: "listServerNeighbors", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.ListServerNeighbors",
    validator: validate_ListServerNeighbors_21626278, base: "/",
    makeUrl: url_ListServerNeighbors_21626279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartContinuousExport_21626292 = ref object of OpenApiRestCall_21625435
proc url_StartContinuousExport_21626294(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartContinuousExport_21626293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626295 = header.getOrDefault("X-Amz-Date")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Date", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Security-Token", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Target")
  valid_21626297 = validateParameter(valid_21626297, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartContinuousExport"))
  if valid_21626297 != nil:
    section.add "X-Amz-Target", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Algorithm", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Signature")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Signature", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Credential")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Credential", valid_21626302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626304: Call_StartContinuousExport_21626292;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_21626304.validator(path, query, header, formData, body, _)
  let scheme = call_21626304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626304.makeUrl(scheme.get, call_21626304.host, call_21626304.base,
                               call_21626304.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626304, uri, valid, _)

proc call*(call_21626305: Call_StartContinuousExport_21626292; body: JsonNode): Recallable =
  ## startContinuousExport
  ## Start the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_21626306 = newJObject()
  if body != nil:
    body_21626306 = body
  result = call_21626305.call(nil, nil, nil, nil, body_21626306)

var startContinuousExport* = Call_StartContinuousExport_21626292(
    name: "startContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartContinuousExport",
    validator: validate_StartContinuousExport_21626293, base: "/",
    makeUrl: url_StartContinuousExport_21626294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartDataCollectionByAgentIds_21626307 = ref object of OpenApiRestCall_21625435
proc url_StartDataCollectionByAgentIds_21626309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartDataCollectionByAgentIds_21626308(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626310 = header.getOrDefault("X-Amz-Date")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Date", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Security-Token", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Target")
  valid_21626312 = validateParameter(valid_21626312, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds"))
  if valid_21626312 != nil:
    section.add "X-Amz-Target", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Algorithm", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Signature")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Signature", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626316
  var valid_21626317 = header.getOrDefault("X-Amz-Credential")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Credential", valid_21626317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626319: Call_StartDataCollectionByAgentIds_21626307;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Instructs the specified agents or connectors to start collecting data.
  ## 
  let valid = call_21626319.validator(path, query, header, formData, body, _)
  let scheme = call_21626319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626319.makeUrl(scheme.get, call_21626319.host, call_21626319.base,
                               call_21626319.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626319, uri, valid, _)

proc call*(call_21626320: Call_StartDataCollectionByAgentIds_21626307;
          body: JsonNode): Recallable =
  ## startDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to start collecting data.
  ##   body: JObject (required)
  var body_21626321 = newJObject()
  if body != nil:
    body_21626321 = body
  result = call_21626320.call(nil, nil, nil, nil, body_21626321)

var startDataCollectionByAgentIds* = Call_StartDataCollectionByAgentIds_21626307(
    name: "startDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartDataCollectionByAgentIds",
    validator: validate_StartDataCollectionByAgentIds_21626308, base: "/",
    makeUrl: url_StartDataCollectionByAgentIds_21626309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportTask_21626322 = ref object of OpenApiRestCall_21625435
proc url_StartExportTask_21626324(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportTask_21626323(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626325 = header.getOrDefault("X-Amz-Date")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Date", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Security-Token", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Target")
  valid_21626327 = validateParameter(valid_21626327, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartExportTask"))
  if valid_21626327 != nil:
    section.add "X-Amz-Target", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Algorithm", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Signature")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Signature", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Credential")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Credential", valid_21626332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626334: Call_StartExportTask_21626322; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ## 
  let valid = call_21626334.validator(path, query, header, formData, body, _)
  let scheme = call_21626334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626334.makeUrl(scheme.get, call_21626334.host, call_21626334.base,
                               call_21626334.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626334, uri, valid, _)

proc call*(call_21626335: Call_StartExportTask_21626322; body: JsonNode): Recallable =
  ## startExportTask
  ## <p> Begins the export of discovered data to an S3 bucket.</p> <p> If you specify <code>agentIds</code> in a filter, the task exports up to 72 hours of detailed data collected by the identified Application Discovery Agent, including network, process, and performance details. A time range for exported agent data may be set by using <code>startTime</code> and <code>endTime</code>. Export of detailed agent data is limited to five concurrently running exports. </p> <p> If you do not include an <code>agentIds</code> filter, summary data is exported that includes both AWS Agentless Discovery Connector data and summary data from AWS Discovery Agents. Export of summary data is limited to two exports per day. </p>
  ##   body: JObject (required)
  var body_21626336 = newJObject()
  if body != nil:
    body_21626336 = body
  result = call_21626335.call(nil, nil, nil, nil, body_21626336)

var startExportTask* = Call_StartExportTask_21626322(name: "startExportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartExportTask",
    validator: validate_StartExportTask_21626323, base: "/",
    makeUrl: url_StartExportTask_21626324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportTask_21626337 = ref object of OpenApiRestCall_21625435
proc url_StartImportTask_21626339(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportTask_21626338(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS Migration Hub without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626340 = header.getOrDefault("X-Amz-Date")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Date", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Security-Token", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Target")
  valid_21626342 = validateParameter(valid_21626342, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StartImportTask"))
  if valid_21626342 != nil:
    section.add "X-Amz-Target", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Algorithm", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Signature")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Signature", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Credential")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Credential", valid_21626347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626349: Call_StartImportTask_21626337; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS Migration Hub without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ## 
  let valid = call_21626349.validator(path, query, header, formData, body, _)
  let scheme = call_21626349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626349.makeUrl(scheme.get, call_21626349.host, call_21626349.base,
                               call_21626349.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626349, uri, valid, _)

proc call*(call_21626350: Call_StartImportTask_21626337; body: JsonNode): Recallable =
  ## startImportTask
  ## <p>Starts an import task, which allows you to import details of your on-premises environment directly into AWS Migration Hub without having to use the Application Discovery Service (ADS) tools such as the Discovery Connector or Discovery Agent. This gives you the option to perform migration assessment and planning directly from your imported data, including the ability to group your devices as applications and track their migration status.</p> <p>To start an import request, do this:</p> <ol> <li> <p>Download the specially formatted comma separated value (CSV) import template, which you can find here: <a href="https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv">https://s3-us-west-2.amazonaws.com/templates-7cffcf56-bd96-4b1c-b45b-a5b42f282e46/import_template.csv</a>.</p> </li> <li> <p>Fill out the template with your server and application data.</p> </li> <li> <p>Upload your import file to an Amazon S3 bucket, and make a note of it's Object URL. Your import file must be in the CSV format.</p> </li> <li> <p>Use the console or the <code>StartImportTask</code> command with the AWS CLI or one of the AWS SDKs to import the records from your file.</p> </li> </ol> <p>For more information, including step-by-step procedures, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/discovery-import.html">Migration Hub Import</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> <note> <p>There are limits to the number of import tasks you can create (and delete) in an AWS account. For more information, see <a href="https://docs.aws.amazon.com/application-discovery/latest/userguide/ads_service_limits.html">AWS Application Discovery Service Limits</a> in the <i>AWS Application Discovery Service User Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_21626351 = newJObject()
  if body != nil:
    body_21626351 = body
  result = call_21626350.call(nil, nil, nil, nil, body_21626351)

var startImportTask* = Call_StartImportTask_21626337(name: "startImportTask",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StartImportTask",
    validator: validate_StartImportTask_21626338, base: "/",
    makeUrl: url_StartImportTask_21626339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopContinuousExport_21626352 = ref object of OpenApiRestCall_21625435
proc url_StopContinuousExport_21626354(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopContinuousExport_21626353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626355 = header.getOrDefault("X-Amz-Date")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Date", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Security-Token", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Target")
  valid_21626357 = validateParameter(valid_21626357, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopContinuousExport"))
  if valid_21626357 != nil:
    section.add "X-Amz-Target", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Algorithm", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Signature")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Signature", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Credential")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Credential", valid_21626362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626364: Call_StopContinuousExport_21626352; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ## 
  let valid = call_21626364.validator(path, query, header, formData, body, _)
  let scheme = call_21626364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626364.makeUrl(scheme.get, call_21626364.host, call_21626364.base,
                               call_21626364.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626364, uri, valid, _)

proc call*(call_21626365: Call_StopContinuousExport_21626352; body: JsonNode): Recallable =
  ## stopContinuousExport
  ## Stop the continuous flow of agent's discovered data into Amazon Athena.
  ##   body: JObject (required)
  var body_21626366 = newJObject()
  if body != nil:
    body_21626366 = body
  result = call_21626365.call(nil, nil, nil, nil, body_21626366)

var stopContinuousExport* = Call_StopContinuousExport_21626352(
    name: "stopContinuousExport", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopContinuousExport",
    validator: validate_StopContinuousExport_21626353, base: "/",
    makeUrl: url_StopContinuousExport_21626354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDataCollectionByAgentIds_21626367 = ref object of OpenApiRestCall_21625435
proc url_StopDataCollectionByAgentIds_21626369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDataCollectionByAgentIds_21626368(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626370 = header.getOrDefault("X-Amz-Date")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Date", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Security-Token", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Target")
  valid_21626372 = validateParameter(valid_21626372, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds"))
  if valid_21626372 != nil:
    section.add "X-Amz-Target", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Algorithm", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-Signature")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Signature", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Credential")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Credential", valid_21626377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626379: Call_StopDataCollectionByAgentIds_21626367;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Instructs the specified agents or connectors to stop collecting data.
  ## 
  let valid = call_21626379.validator(path, query, header, formData, body, _)
  let scheme = call_21626379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626379.makeUrl(scheme.get, call_21626379.host, call_21626379.base,
                               call_21626379.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626379, uri, valid, _)

proc call*(call_21626380: Call_StopDataCollectionByAgentIds_21626367;
          body: JsonNode): Recallable =
  ## stopDataCollectionByAgentIds
  ## Instructs the specified agents or connectors to stop collecting data.
  ##   body: JObject (required)
  var body_21626381 = newJObject()
  if body != nil:
    body_21626381 = body
  result = call_21626380.call(nil, nil, nil, nil, body_21626381)

var stopDataCollectionByAgentIds* = Call_StopDataCollectionByAgentIds_21626367(
    name: "stopDataCollectionByAgentIds", meth: HttpMethod.HttpPost,
    host: "discovery.amazonaws.com", route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.StopDataCollectionByAgentIds",
    validator: validate_StopDataCollectionByAgentIds_21626368, base: "/",
    makeUrl: url_StopDataCollectionByAgentIds_21626369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_21626382 = ref object of OpenApiRestCall_21625435
proc url_UpdateApplication_21626384(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_21626383(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates metadata about an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626385 = header.getOrDefault("X-Amz-Date")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Date", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Security-Token", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Target")
  valid_21626387 = validateParameter(valid_21626387, JString, required = true, default = newJString(
      "AWSPoseidonService_V2015_11_01.UpdateApplication"))
  if valid_21626387 != nil:
    section.add "X-Amz-Target", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-Algorithm", valid_21626389
  var valid_21626390 = header.getOrDefault("X-Amz-Signature")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Signature", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Credential")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Credential", valid_21626392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626394: Call_UpdateApplication_21626382; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates metadata about an application.
  ## 
  let valid = call_21626394.validator(path, query, header, formData, body, _)
  let scheme = call_21626394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626394.makeUrl(scheme.get, call_21626394.host, call_21626394.base,
                               call_21626394.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626394, uri, valid, _)

proc call*(call_21626395: Call_UpdateApplication_21626382; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates metadata about an application.
  ##   body: JObject (required)
  var body_21626396 = newJObject()
  if body != nil:
    body_21626396 = body
  result = call_21626395.call(nil, nil, nil, nil, body_21626396)

var updateApplication* = Call_UpdateApplication_21626382(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "discovery.amazonaws.com",
    route: "/#X-Amz-Target=AWSPoseidonService_V2015_11_01.UpdateApplication",
    validator: validate_UpdateApplication_21626383, base: "/",
    makeUrl: url_UpdateApplication_21626384, schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}