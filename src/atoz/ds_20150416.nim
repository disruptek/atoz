
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Directory Service
## version: 2015-04-16
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Directory Service</fullname> <p>AWS Directory Service is a web service that makes it easy for you to setup and run directories in the AWS cloud, or connect your AWS resources with an existing on-premises Microsoft Active Directory. This guide provides detailed information about AWS Directory Service operations, data types, parameters, and errors. For information about AWS Directory Services features, see <a href="https://aws.amazon.com/directoryservice/">AWS Directory Service</a> and the <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/what_is.html">AWS Directory Service Administration Guide</a>.</p> <note> <p>AWS provides SDKs that consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .Net, iOS, Android, etc.). The SDKs provide a convenient way to create programmatic access to AWS Directory Service and other AWS services. For more information about the AWS SDKs, including how to download and install them, see <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> </note>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ds/
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ds.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "ds.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ds.us-west-2.amazonaws.com",
                           "eu-west-2": "ds.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "ds.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ds.eu-central-1.amazonaws.com",
                           "us-east-2": "ds.us-east-2.amazonaws.com",
                           "us-east-1": "ds.us-east-1.amazonaws.com", "cn-northwest-1": "ds.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ds.ap-south-1.amazonaws.com",
                           "eu-north-1": "ds.eu-north-1.amazonaws.com",
                           "ap-northeast-2": "ds.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ds.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ds.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ds.eu-west-3.amazonaws.com",
                           "cn-north-1": "ds.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ds.sa-east-1.amazonaws.com",
                           "eu-west-1": "ds.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ds.us-gov-west-1.amazonaws.com",
                           "ap-southeast-2": "ds.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ds.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ds.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ds.ap-southeast-1.amazonaws.com",
      "us-west-2": "ds.us-west-2.amazonaws.com",
      "eu-west-2": "ds.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ds.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ds.eu-central-1.amazonaws.com",
      "us-east-2": "ds.us-east-2.amazonaws.com",
      "us-east-1": "ds.us-east-1.amazonaws.com",
      "cn-northwest-1": "ds.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ds.ap-south-1.amazonaws.com",
      "eu-north-1": "ds.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ds.ap-northeast-2.amazonaws.com",
      "us-west-1": "ds.us-west-1.amazonaws.com",
      "us-gov-east-1": "ds.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ds.eu-west-3.amazonaws.com",
      "cn-north-1": "ds.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ds.sa-east-1.amazonaws.com",
      "eu-west-1": "ds.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ds.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ds.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ds.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ds"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptSharedDirectory_601727 = ref object of OpenApiRestCall_601389
proc url_AcceptSharedDirectory_601729(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptSharedDirectory_601728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Accepts a directory sharing request that was sent from the directory owner account.
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
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "DirectoryService_20150416.AcceptSharedDirectory"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AcceptSharedDirectory_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AcceptSharedDirectory_601727; body: JsonNode): Recallable =
  ## acceptSharedDirectory
  ## Accepts a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var acceptSharedDirectory* = Call_AcceptSharedDirectory_601727(
    name: "acceptSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AcceptSharedDirectory",
    validator: validate_AcceptSharedDirectory_601728, base: "/",
    url: url_AcceptSharedDirectory_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddIpRoutes_601996 = ref object of OpenApiRestCall_601389
proc url_AddIpRoutes_601998(protocol: Scheme; host: string; base: string;
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

proc validate_AddIpRoutes_601997(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "DirectoryService_20150416.AddIpRoutes"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_AddIpRoutes_601996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_AddIpRoutes_601996; body: JsonNode): Recallable =
  ## addIpRoutes
  ## <p>If the DNS server for your on-premises domain uses a publicly addressable IP address, you must add a CIDR address block to correctly route traffic to and from your Microsoft AD on Amazon Web Services. <i>AddIpRoutes</i> adds this address block. You can also use <i>AddIpRoutes</i> to facilitate routing traffic that uses public IP ranges from your Microsoft AD on AWS to a peer VPC. </p> <p>Before you call <i>AddIpRoutes</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>AddIpRoutes</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var addIpRoutes* = Call_AddIpRoutes_601996(name: "addIpRoutes",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.AddIpRoutes",
                                        validator: validate_AddIpRoutes_601997,
                                        base: "/", url: url_AddIpRoutes_601998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTagsToResource_602011 = ref object of OpenApiRestCall_601389
proc url_AddTagsToResource_602013(protocol: Scheme; host: string; base: string;
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

proc validate_AddTagsToResource_602012(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
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
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "DirectoryService_20150416.AddTagsToResource"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_AddTagsToResource_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_AddTagsToResource_602011; body: JsonNode): Recallable =
  ## addTagsToResource
  ## Adds or overwrites one or more tags for the specified directory. Each directory can have a maximum of 50 tags. Each tag consists of a key and optional value. Tag keys must be unique to each resource.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var addTagsToResource* = Call_AddTagsToResource_602011(name: "addTagsToResource",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.AddTagsToResource",
    validator: validate_AddTagsToResource_602012, base: "/",
    url: url_AddTagsToResource_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSchemaExtension_602026 = ref object of OpenApiRestCall_601389
proc url_CancelSchemaExtension_602028(protocol: Scheme; host: string; base: string;
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

proc validate_CancelSchemaExtension_602027(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
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
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "DirectoryService_20150416.CancelSchemaExtension"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CancelSchemaExtension_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CancelSchemaExtension_602026; body: JsonNode): Recallable =
  ## cancelSchemaExtension
  ## Cancels an in-progress schema extension to a Microsoft AD directory. Once a schema extension has started replicating to all domain controllers, the task can no longer be canceled. A schema extension can be canceled during any of the following states; <code>Initializing</code>, <code>CreatingSnapshot</code>, and <code>UpdatingSchema</code>.
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var cancelSchemaExtension* = Call_CancelSchemaExtension_602026(
    name: "cancelSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CancelSchemaExtension",
    validator: validate_CancelSchemaExtension_602027, base: "/",
    url: url_CancelSchemaExtension_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ConnectDirectory_602041 = ref object of OpenApiRestCall_601389
proc url_ConnectDirectory_602043(protocol: Scheme; host: string; base: string;
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

proc validate_ConnectDirectory_602042(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "DirectoryService_20150416.ConnectDirectory"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_ConnectDirectory_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_ConnectDirectory_602041; body: JsonNode): Recallable =
  ## connectDirectory
  ## <p>Creates an AD Connector to connect to an on-premises directory.</p> <p>Before you call <code>ConnectDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>ConnectDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var connectDirectory* = Call_ConnectDirectory_602041(name: "connectDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ConnectDirectory",
    validator: validate_ConnectDirectory_602042, base: "/",
    url: url_ConnectDirectory_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_602056 = ref object of OpenApiRestCall_601389
proc url_CreateAlias_602058(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlias_602057(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
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
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateAlias"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_CreateAlias_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_CreateAlias_602056; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an alias for a directory and assigns the alias to the directory. The alias is used to construct the access URL for the directory, such as <code>http://&lt;alias&gt;.awsapps.com</code>.</p> <important> <p>After an alias has been created, it cannot be deleted or reused, so this operation should only be used when absolutely necessary.</p> </important>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var createAlias* = Call_CreateAlias_602056(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateAlias",
                                        validator: validate_CreateAlias_602057,
                                        base: "/", url: url_CreateAlias_602058,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputer_602071 = ref object of OpenApiRestCall_601389
proc url_CreateComputer_602073(protocol: Scheme; host: string; base: string;
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

proc validate_CreateComputer_602072(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
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
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateComputer"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_CreateComputer_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_CreateComputer_602071; body: JsonNode): Recallable =
  ## createComputer
  ## Creates a computer account in the specified directory, and joins the computer to the directory.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var createComputer* = Call_CreateComputer_602071(name: "createComputer",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateComputer",
    validator: validate_CreateComputer_602072, base: "/", url: url_CreateComputer_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConditionalForwarder_602086 = ref object of OpenApiRestCall_601389
proc url_CreateConditionalForwarder_602088(protocol: Scheme; host: string;
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

proc validate_CreateConditionalForwarder_602087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
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
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateConditionalForwarder"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_CreateConditionalForwarder_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_CreateConditionalForwarder_602086; body: JsonNode): Recallable =
  ## createConditionalForwarder
  ## Creates a conditional forwarder associated with your AWS directory. Conditional forwarders are required in order to set up a trust relationship with another domain. The conditional forwarder points to the trusted domain.
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var createConditionalForwarder* = Call_CreateConditionalForwarder_602086(
    name: "createConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateConditionalForwarder",
    validator: validate_CreateConditionalForwarder_602087, base: "/",
    url: url_CreateConditionalForwarder_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDirectory_602101 = ref object of OpenApiRestCall_601389
proc url_CreateDirectory_602103(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDirectory_602102(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateDirectory"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_CreateDirectory_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_CreateDirectory_602101; body: JsonNode): Recallable =
  ## createDirectory
  ## <p>Creates a Simple AD directory. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_simple_ad.html">Simple Active Directory</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <code>CreateDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>CreateDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var createDirectory* = Call_CreateDirectory_602101(name: "createDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateDirectory",
    validator: validate_CreateDirectory_602102, base: "/", url: url_CreateDirectory_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogSubscription_602116 = ref object of OpenApiRestCall_601389
proc url_CreateLogSubscription_602118(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLogSubscription_602117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
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
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateLogSubscription"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_CreateLogSubscription_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_CreateLogSubscription_602116; body: JsonNode): Recallable =
  ## createLogSubscription
  ## Creates a subscription to forward real-time Directory Service domain controller security logs to the specified Amazon CloudWatch log group in your AWS account.
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var createLogSubscription* = Call_CreateLogSubscription_602116(
    name: "createLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateLogSubscription",
    validator: validate_CreateLogSubscription_602117, base: "/",
    url: url_CreateLogSubscription_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMicrosoftAD_602131 = ref object of OpenApiRestCall_601389
proc url_CreateMicrosoftAD_602133(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMicrosoftAD_602132(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateMicrosoftAD"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_CreateMicrosoftAD_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_CreateMicrosoftAD_602131; body: JsonNode): Recallable =
  ## createMicrosoftAD
  ## <p>Creates a Microsoft AD directory in the AWS Cloud. For more information, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html">AWS Managed Microsoft AD</a> in the <i>AWS Directory Service Admin Guide</i>.</p> <p>Before you call <i>CreateMicrosoftAD</i>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <i>CreateMicrosoftAD</i> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var createMicrosoftAD* = Call_CreateMicrosoftAD_602131(name: "createMicrosoftAD",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateMicrosoftAD",
    validator: validate_CreateMicrosoftAD_602132, base: "/",
    url: url_CreateMicrosoftAD_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSnapshot_602146 = ref object of OpenApiRestCall_601389
proc url_CreateSnapshot_602148(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSnapshot_602147(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
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
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateSnapshot"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_CreateSnapshot_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_CreateSnapshot_602146; body: JsonNode): Recallable =
  ## createSnapshot
  ## <p>Creates a snapshot of a Simple AD or Microsoft AD directory in the AWS cloud.</p> <note> <p>You cannot take snapshots of AD Connector directories.</p> </note>
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var createSnapshot* = Call_CreateSnapshot_602146(name: "createSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.CreateSnapshot",
    validator: validate_CreateSnapshot_602147, base: "/", url: url_CreateSnapshot_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrust_602161 = ref object of OpenApiRestCall_601389
proc url_CreateTrust_602163(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrust_602162(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
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
  var valid_602164 = header.getOrDefault("X-Amz-Target")
  valid_602164 = validateParameter(valid_602164, JString, required = true, default = newJString(
      "DirectoryService_20150416.CreateTrust"))
  if valid_602164 != nil:
    section.add "X-Amz-Target", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_CreateTrust_602161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_CreateTrust_602161; body: JsonNode): Recallable =
  ## createTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure trust relationships. For example, you can establish a trust between your AWS Managed Microsoft AD directory, and your existing on-premises Microsoft Active Directory. This would allow you to provide users and groups access to resources in either domain, with a single set of credentials.</p> <p>This action initiates the creation of the AWS side of a trust relationship between an AWS Managed Microsoft AD directory and an external domain. You can create either a forest trust or an external trust.</p>
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var createTrust* = Call_CreateTrust_602161(name: "createTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.CreateTrust",
                                        validator: validate_CreateTrust_602162,
                                        base: "/", url: url_CreateTrust_602163,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConditionalForwarder_602176 = ref object of OpenApiRestCall_601389
proc url_DeleteConditionalForwarder_602178(protocol: Scheme; host: string;
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

proc validate_DeleteConditionalForwarder_602177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
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
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteConditionalForwarder"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_DeleteConditionalForwarder_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_DeleteConditionalForwarder_602176; body: JsonNode): Recallable =
  ## deleteConditionalForwarder
  ## Deletes a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var deleteConditionalForwarder* = Call_DeleteConditionalForwarder_602176(
    name: "deleteConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteConditionalForwarder",
    validator: validate_DeleteConditionalForwarder_602177, base: "/",
    url: url_DeleteConditionalForwarder_602178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDirectory_602191 = ref object of OpenApiRestCall_601389
proc url_DeleteDirectory_602193(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDirectory_602192(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
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
  var valid_602194 = header.getOrDefault("X-Amz-Target")
  valid_602194 = validateParameter(valid_602194, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteDirectory"))
  if valid_602194 != nil:
    section.add "X-Amz-Target", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_DeleteDirectory_602191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_DeleteDirectory_602191; body: JsonNode): Recallable =
  ## deleteDirectory
  ## <p>Deletes an AWS Directory Service directory.</p> <p>Before you call <code>DeleteDirectory</code>, ensure that all of the required permissions have been explicitly granted through a policy. For details about what permissions are required to run the <code>DeleteDirectory</code> operation, see <a href="http://docs.aws.amazon.com/directoryservice/latest/admin-guide/UsingWithDS_IAM_ResourcePermissions.html">AWS Directory Service API Permissions: Actions, Resources, and Conditions Reference</a>.</p>
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var deleteDirectory* = Call_DeleteDirectory_602191(name: "deleteDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteDirectory",
    validator: validate_DeleteDirectory_602192, base: "/", url: url_DeleteDirectory_602193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogSubscription_602206 = ref object of OpenApiRestCall_601389
proc url_DeleteLogSubscription_602208(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLogSubscription_602207(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified log subscription.
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
  var valid_602209 = header.getOrDefault("X-Amz-Target")
  valid_602209 = validateParameter(valid_602209, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteLogSubscription"))
  if valid_602209 != nil:
    section.add "X-Amz-Target", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_DeleteLogSubscription_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified log subscription.
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_DeleteLogSubscription_602206; body: JsonNode): Recallable =
  ## deleteLogSubscription
  ## Deletes the specified log subscription.
  ##   body: JObject (required)
  var body_602220 = newJObject()
  if body != nil:
    body_602220 = body
  result = call_602219.call(nil, nil, nil, nil, body_602220)

var deleteLogSubscription* = Call_DeleteLogSubscription_602206(
    name: "deleteLogSubscription", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteLogSubscription",
    validator: validate_DeleteLogSubscription_602207, base: "/",
    url: url_DeleteLogSubscription_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSnapshot_602221 = ref object of OpenApiRestCall_601389
proc url_DeleteSnapshot_602223(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSnapshot_602222(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a directory snapshot.
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
  var valid_602224 = header.getOrDefault("X-Amz-Target")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteSnapshot"))
  if valid_602224 != nil:
    section.add "X-Amz-Target", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_DeleteSnapshot_602221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a directory snapshot.
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_DeleteSnapshot_602221; body: JsonNode): Recallable =
  ## deleteSnapshot
  ## Deletes a directory snapshot.
  ##   body: JObject (required)
  var body_602235 = newJObject()
  if body != nil:
    body_602235 = body
  result = call_602234.call(nil, nil, nil, nil, body_602235)

var deleteSnapshot* = Call_DeleteSnapshot_602221(name: "deleteSnapshot",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeleteSnapshot",
    validator: validate_DeleteSnapshot_602222, base: "/", url: url_DeleteSnapshot_602223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrust_602236 = ref object of OpenApiRestCall_601389
proc url_DeleteTrust_602238(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrust_602237(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
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
  var valid_602239 = header.getOrDefault("X-Amz-Target")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeleteTrust"))
  if valid_602239 != nil:
    section.add "X-Amz-Target", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_DeleteTrust_602236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_DeleteTrust_602236; body: JsonNode): Recallable =
  ## deleteTrust
  ## Deletes an existing trust relationship between your AWS Managed Microsoft AD directory and an external domain.
  ##   body: JObject (required)
  var body_602250 = newJObject()
  if body != nil:
    body_602250 = body
  result = call_602249.call(nil, nil, nil, nil, body_602250)

var deleteTrust* = Call_DeleteTrust_602236(name: "deleteTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DeleteTrust",
                                        validator: validate_DeleteTrust_602237,
                                        base: "/", url: url_DeleteTrust_602238,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterCertificate_602251 = ref object of OpenApiRestCall_601389
proc url_DeregisterCertificate_602253(protocol: Scheme; host: string; base: string;
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

proc validate_DeregisterCertificate_602252(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
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
  var valid_602254 = header.getOrDefault("X-Amz-Target")
  valid_602254 = validateParameter(valid_602254, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterCertificate"))
  if valid_602254 != nil:
    section.add "X-Amz-Target", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_DeregisterCertificate_602251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_DeregisterCertificate_602251; body: JsonNode): Recallable =
  ## deregisterCertificate
  ## Deletes from the system the certificate that was registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_602265 = newJObject()
  if body != nil:
    body_602265 = body
  result = call_602264.call(nil, nil, nil, nil, body_602265)

var deregisterCertificate* = Call_DeregisterCertificate_602251(
    name: "deregisterCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterCertificate",
    validator: validate_DeregisterCertificate_602252, base: "/",
    url: url_DeregisterCertificate_602253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterEventTopic_602266 = ref object of OpenApiRestCall_601389
proc url_DeregisterEventTopic_602268(protocol: Scheme; host: string; base: string;
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

proc validate_DeregisterEventTopic_602267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified directory as a publisher to the specified SNS topic.
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
  var valid_602269 = header.getOrDefault("X-Amz-Target")
  valid_602269 = validateParameter(valid_602269, JString, required = true, default = newJString(
      "DirectoryService_20150416.DeregisterEventTopic"))
  if valid_602269 != nil:
    section.add "X-Amz-Target", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Signature")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Signature", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Content-Sha256", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Date")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Date", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Credential")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Credential", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Security-Token")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Security-Token", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Algorithm")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Algorithm", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-SignedHeaders", valid_602276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602278: Call_DeregisterEventTopic_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ## 
  let valid = call_602278.validator(path, query, header, formData, body)
  let scheme = call_602278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602278.url(scheme.get, call_602278.host, call_602278.base,
                         call_602278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602278, url, valid)

proc call*(call_602279: Call_DeregisterEventTopic_602266; body: JsonNode): Recallable =
  ## deregisterEventTopic
  ## Removes the specified directory as a publisher to the specified SNS topic.
  ##   body: JObject (required)
  var body_602280 = newJObject()
  if body != nil:
    body_602280 = body
  result = call_602279.call(nil, nil, nil, nil, body_602280)

var deregisterEventTopic* = Call_DeregisterEventTopic_602266(
    name: "deregisterEventTopic", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DeregisterEventTopic",
    validator: validate_DeregisterEventTopic_602267, base: "/",
    url: url_DeregisterEventTopic_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCertificate_602281 = ref object of OpenApiRestCall_601389
proc url_DescribeCertificate_602283(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCertificate_602282(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Displays information about the certificate registered for a secured LDAP connection.
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
  var valid_602284 = header.getOrDefault("X-Amz-Target")
  valid_602284 = validateParameter(valid_602284, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeCertificate"))
  if valid_602284 != nil:
    section.add "X-Amz-Target", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Signature")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Signature", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Content-Sha256", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Date")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Date", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Credential")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Credential", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Security-Token")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Security-Token", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Algorithm")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Algorithm", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-SignedHeaders", valid_602291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602293: Call_DescribeCertificate_602281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Displays information about the certificate registered for a secured LDAP connection.
  ## 
  let valid = call_602293.validator(path, query, header, formData, body)
  let scheme = call_602293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602293.url(scheme.get, call_602293.host, call_602293.base,
                         call_602293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602293, url, valid)

proc call*(call_602294: Call_DescribeCertificate_602281; body: JsonNode): Recallable =
  ## describeCertificate
  ## Displays information about the certificate registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_602295 = newJObject()
  if body != nil:
    body_602295 = body
  result = call_602294.call(nil, nil, nil, nil, body_602295)

var describeCertificate* = Call_DescribeCertificate_602281(
    name: "describeCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeCertificate",
    validator: validate_DescribeCertificate_602282, base: "/",
    url: url_DescribeCertificate_602283, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConditionalForwarders_602296 = ref object of OpenApiRestCall_601389
proc url_DescribeConditionalForwarders_602298(protocol: Scheme; host: string;
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

proc validate_DescribeConditionalForwarders_602297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
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
  var valid_602299 = header.getOrDefault("X-Amz-Target")
  valid_602299 = validateParameter(valid_602299, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeConditionalForwarders"))
  if valid_602299 != nil:
    section.add "X-Amz-Target", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602308: Call_DescribeConditionalForwarders_602296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ## 
  let valid = call_602308.validator(path, query, header, formData, body)
  let scheme = call_602308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602308.url(scheme.get, call_602308.host, call_602308.base,
                         call_602308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602308, url, valid)

proc call*(call_602309: Call_DescribeConditionalForwarders_602296; body: JsonNode): Recallable =
  ## describeConditionalForwarders
  ## <p>Obtains information about the conditional forwarders for this account.</p> <p>If no input parameters are provided for RemoteDomainNames, this request describes all conditional forwarders for the specified directory ID.</p>
  ##   body: JObject (required)
  var body_602310 = newJObject()
  if body != nil:
    body_602310 = body
  result = call_602309.call(nil, nil, nil, nil, body_602310)

var describeConditionalForwarders* = Call_DescribeConditionalForwarders_602296(
    name: "describeConditionalForwarders", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeConditionalForwarders",
    validator: validate_DescribeConditionalForwarders_602297, base: "/",
    url: url_DescribeConditionalForwarders_602298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDirectories_602311 = ref object of OpenApiRestCall_601389
proc url_DescribeDirectories_602313(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDirectories_602312(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
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
  var valid_602314 = header.getOrDefault("X-Amz-Target")
  valid_602314 = validateParameter(valid_602314, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDirectories"))
  if valid_602314 != nil:
    section.add "X-Amz-Target", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Content-Sha256", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Date")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Date", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Credential")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Credential", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Security-Token")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Security-Token", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Algorithm")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Algorithm", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-SignedHeaders", valid_602321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602323: Call_DescribeDirectories_602311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ## 
  let valid = call_602323.validator(path, query, header, formData, body)
  let scheme = call_602323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602323.url(scheme.get, call_602323.host, call_602323.base,
                         call_602323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602323, url, valid)

proc call*(call_602324: Call_DescribeDirectories_602311; body: JsonNode): Recallable =
  ## describeDirectories
  ## <p>Obtains information about the directories that belong to this account.</p> <p>You can retrieve information about specific directories by passing the directory identifiers in the <code>DirectoryIds</code> parameter. Otherwise, all directories that belong to the current account are returned.</p> <p>This operation supports pagination with the use of the <code>NextToken</code> request and response parameters. If more results are available, the <code>DescribeDirectoriesResult.NextToken</code> member contains a token that you pass in the next call to <a>DescribeDirectories</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <code>Limit</code> parameter.</p>
  ##   body: JObject (required)
  var body_602325 = newJObject()
  if body != nil:
    body_602325 = body
  result = call_602324.call(nil, nil, nil, nil, body_602325)

var describeDirectories* = Call_DescribeDirectories_602311(
    name: "describeDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDirectories",
    validator: validate_DescribeDirectories_602312, base: "/",
    url: url_DescribeDirectories_602313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDomainControllers_602326 = ref object of OpenApiRestCall_601389
proc url_DescribeDomainControllers_602328(protocol: Scheme; host: string;
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

proc validate_DescribeDomainControllers_602327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information about any domain controllers in your directory.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   Limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_602329 = query.getOrDefault("NextToken")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "NextToken", valid_602329
  var valid_602330 = query.getOrDefault("Limit")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "Limit", valid_602330
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
  var valid_602331 = header.getOrDefault("X-Amz-Target")
  valid_602331 = validateParameter(valid_602331, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeDomainControllers"))
  if valid_602331 != nil:
    section.add "X-Amz-Target", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Signature")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Signature", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Content-Sha256", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Date")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Date", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Credential")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Credential", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Security-Token")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Security-Token", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Algorithm")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Algorithm", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-SignedHeaders", valid_602338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602340: Call_DescribeDomainControllers_602326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about any domain controllers in your directory.
  ## 
  let valid = call_602340.validator(path, query, header, formData, body)
  let scheme = call_602340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602340.url(scheme.get, call_602340.host, call_602340.base,
                         call_602340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602340, url, valid)

proc call*(call_602341: Call_DescribeDomainControllers_602326; body: JsonNode;
          NextToken: string = ""; Limit: string = ""): Recallable =
  ## describeDomainControllers
  ## Provides information about any domain controllers in your directory.
  ##   NextToken: string
  ##            : Pagination token
  ##   Limit: string
  ##        : Pagination limit
  ##   body: JObject (required)
  var query_602342 = newJObject()
  var body_602343 = newJObject()
  add(query_602342, "NextToken", newJString(NextToken))
  add(query_602342, "Limit", newJString(Limit))
  if body != nil:
    body_602343 = body
  result = call_602341.call(nil, query_602342, nil, nil, body_602343)

var describeDomainControllers* = Call_DescribeDomainControllers_602326(
    name: "describeDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeDomainControllers",
    validator: validate_DescribeDomainControllers_602327, base: "/",
    url: url_DescribeDomainControllers_602328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEventTopics_602345 = ref object of OpenApiRestCall_601389
proc url_DescribeEventTopics_602347(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeEventTopics_602346(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
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
  var valid_602348 = header.getOrDefault("X-Amz-Target")
  valid_602348 = validateParameter(valid_602348, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeEventTopics"))
  if valid_602348 != nil:
    section.add "X-Amz-Target", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Signature")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Signature", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Content-Sha256", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Date")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Date", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Credential")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Credential", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Security-Token")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Security-Token", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Algorithm")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Algorithm", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-SignedHeaders", valid_602355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602357: Call_DescribeEventTopics_602345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ## 
  let valid = call_602357.validator(path, query, header, formData, body)
  let scheme = call_602357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602357.url(scheme.get, call_602357.host, call_602357.base,
                         call_602357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602357, url, valid)

proc call*(call_602358: Call_DescribeEventTopics_602345; body: JsonNode): Recallable =
  ## describeEventTopics
  ## <p>Obtains information about which SNS topics receive status messages from the specified directory.</p> <p>If no input parameters are provided, such as DirectoryId or TopicName, this request describes all of the associations in the account.</p>
  ##   body: JObject (required)
  var body_602359 = newJObject()
  if body != nil:
    body_602359 = body
  result = call_602358.call(nil, nil, nil, nil, body_602359)

var describeEventTopics* = Call_DescribeEventTopics_602345(
    name: "describeEventTopics", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeEventTopics",
    validator: validate_DescribeEventTopics_602346, base: "/",
    url: url_DescribeEventTopics_602347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLDAPSSettings_602360 = ref object of OpenApiRestCall_601389
proc url_DescribeLDAPSSettings_602362(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLDAPSSettings_602361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the status of LDAP security for the specified directory.
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
  var valid_602363 = header.getOrDefault("X-Amz-Target")
  valid_602363 = validateParameter(valid_602363, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeLDAPSSettings"))
  if valid_602363 != nil:
    section.add "X-Amz-Target", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Signature")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Signature", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Content-Sha256", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Date")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Date", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Credential")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Credential", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Security-Token")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Security-Token", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Algorithm")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Algorithm", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-SignedHeaders", valid_602370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602372: Call_DescribeLDAPSSettings_602360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the status of LDAP security for the specified directory.
  ## 
  let valid = call_602372.validator(path, query, header, formData, body)
  let scheme = call_602372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602372.url(scheme.get, call_602372.host, call_602372.base,
                         call_602372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602372, url, valid)

proc call*(call_602373: Call_DescribeLDAPSSettings_602360; body: JsonNode): Recallable =
  ## describeLDAPSSettings
  ## Describes the status of LDAP security for the specified directory.
  ##   body: JObject (required)
  var body_602374 = newJObject()
  if body != nil:
    body_602374 = body
  result = call_602373.call(nil, nil, nil, nil, body_602374)

var describeLDAPSSettings* = Call_DescribeLDAPSSettings_602360(
    name: "describeLDAPSSettings", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeLDAPSSettings",
    validator: validate_DescribeLDAPSSettings_602361, base: "/",
    url: url_DescribeLDAPSSettings_602362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSharedDirectories_602375 = ref object of OpenApiRestCall_601389
proc url_DescribeSharedDirectories_602377(protocol: Scheme; host: string;
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

proc validate_DescribeSharedDirectories_602376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the shared directories in your account. 
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
  var valid_602378 = header.getOrDefault("X-Amz-Target")
  valid_602378 = validateParameter(valid_602378, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSharedDirectories"))
  if valid_602378 != nil:
    section.add "X-Amz-Target", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Signature")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Signature", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Content-Sha256", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Date")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Date", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Credential")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Credential", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Security-Token")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Security-Token", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Algorithm")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Algorithm", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-SignedHeaders", valid_602385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602387: Call_DescribeSharedDirectories_602375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the shared directories in your account. 
  ## 
  let valid = call_602387.validator(path, query, header, formData, body)
  let scheme = call_602387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602387.url(scheme.get, call_602387.host, call_602387.base,
                         call_602387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602387, url, valid)

proc call*(call_602388: Call_DescribeSharedDirectories_602375; body: JsonNode): Recallable =
  ## describeSharedDirectories
  ## Returns the shared directories in your account. 
  ##   body: JObject (required)
  var body_602389 = newJObject()
  if body != nil:
    body_602389 = body
  result = call_602388.call(nil, nil, nil, nil, body_602389)

var describeSharedDirectories* = Call_DescribeSharedDirectories_602375(
    name: "describeSharedDirectories", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSharedDirectories",
    validator: validate_DescribeSharedDirectories_602376, base: "/",
    url: url_DescribeSharedDirectories_602377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSnapshots_602390 = ref object of OpenApiRestCall_601389
proc url_DescribeSnapshots_602392(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSnapshots_602391(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
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
  var valid_602393 = header.getOrDefault("X-Amz-Target")
  valid_602393 = validateParameter(valid_602393, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeSnapshots"))
  if valid_602393 != nil:
    section.add "X-Amz-Target", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Signature")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Signature", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Content-Sha256", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Date")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Date", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Credential")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Credential", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Security-Token")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Security-Token", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602402: Call_DescribeSnapshots_602390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ## 
  let valid = call_602402.validator(path, query, header, formData, body)
  let scheme = call_602402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602402.url(scheme.get, call_602402.host, call_602402.base,
                         call_602402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602402, url, valid)

proc call*(call_602403: Call_DescribeSnapshots_602390; body: JsonNode): Recallable =
  ## describeSnapshots
  ## <p>Obtains information about the directory snapshots that belong to this account.</p> <p>This operation supports pagination with the use of the <i>NextToken</i> request and response parameters. If more results are available, the <i>DescribeSnapshots.NextToken</i> member contains a token that you pass in the next call to <a>DescribeSnapshots</a> to retrieve the next set of items.</p> <p>You can also specify a maximum number of return results with the <i>Limit</i> parameter.</p>
  ##   body: JObject (required)
  var body_602404 = newJObject()
  if body != nil:
    body_602404 = body
  result = call_602403.call(nil, nil, nil, nil, body_602404)

var describeSnapshots* = Call_DescribeSnapshots_602390(name: "describeSnapshots",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeSnapshots",
    validator: validate_DescribeSnapshots_602391, base: "/",
    url: url_DescribeSnapshots_602392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrusts_602405 = ref object of OpenApiRestCall_601389
proc url_DescribeTrusts_602407(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrusts_602406(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
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
  var valid_602408 = header.getOrDefault("X-Amz-Target")
  valid_602408 = validateParameter(valid_602408, JString, required = true, default = newJString(
      "DirectoryService_20150416.DescribeTrusts"))
  if valid_602408 != nil:
    section.add "X-Amz-Target", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Signature")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Signature", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Content-Sha256", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Date")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Date", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Credential")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Credential", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Security-Token")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Security-Token", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Algorithm")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Algorithm", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-SignedHeaders", valid_602415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602417: Call_DescribeTrusts_602405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ## 
  let valid = call_602417.validator(path, query, header, formData, body)
  let scheme = call_602417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602417.url(scheme.get, call_602417.host, call_602417.base,
                         call_602417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602417, url, valid)

proc call*(call_602418: Call_DescribeTrusts_602405; body: JsonNode): Recallable =
  ## describeTrusts
  ## <p>Obtains information about the trust relationships for this account.</p> <p>If no input parameters are provided, such as DirectoryId or TrustIds, this request describes all the trust relationships belonging to the account.</p>
  ##   body: JObject (required)
  var body_602419 = newJObject()
  if body != nil:
    body_602419 = body
  result = call_602418.call(nil, nil, nil, nil, body_602419)

var describeTrusts* = Call_DescribeTrusts_602405(name: "describeTrusts",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DescribeTrusts",
    validator: validate_DescribeTrusts_602406, base: "/", url: url_DescribeTrusts_602407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableLDAPS_602420 = ref object of OpenApiRestCall_601389
proc url_DisableLDAPS_602422(protocol: Scheme; host: string; base: string;
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

proc validate_DisableLDAPS_602421(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deactivates LDAP secure calls for the specified directory.
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
  var valid_602423 = header.getOrDefault("X-Amz-Target")
  valid_602423 = validateParameter(valid_602423, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableLDAPS"))
  if valid_602423 != nil:
    section.add "X-Amz-Target", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Signature")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Signature", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Content-Sha256", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Date")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Date", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Credential")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Credential", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Security-Token")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Security-Token", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Algorithm")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Algorithm", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-SignedHeaders", valid_602430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602432: Call_DisableLDAPS_602420; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deactivates LDAP secure calls for the specified directory.
  ## 
  let valid = call_602432.validator(path, query, header, formData, body)
  let scheme = call_602432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602432.url(scheme.get, call_602432.host, call_602432.base,
                         call_602432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602432, url, valid)

proc call*(call_602433: Call_DisableLDAPS_602420; body: JsonNode): Recallable =
  ## disableLDAPS
  ## Deactivates LDAP secure calls for the specified directory.
  ##   body: JObject (required)
  var body_602434 = newJObject()
  if body != nil:
    body_602434 = body
  result = call_602433.call(nil, nil, nil, nil, body_602434)

var disableLDAPS* = Call_DisableLDAPS_602420(name: "disableLDAPS",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableLDAPS",
    validator: validate_DisableLDAPS_602421, base: "/", url: url_DisableLDAPS_602422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableRadius_602435 = ref object of OpenApiRestCall_601389
proc url_DisableRadius_602437(protocol: Scheme; host: string; base: string;
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

proc validate_DisableRadius_602436(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
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
  var valid_602438 = header.getOrDefault("X-Amz-Target")
  valid_602438 = validateParameter(valid_602438, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableRadius"))
  if valid_602438 != nil:
    section.add "X-Amz-Target", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Signature")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Signature", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Content-Sha256", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Date")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Date", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Credential")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Credential", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Security-Token")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Security-Token", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Algorithm")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Algorithm", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-SignedHeaders", valid_602445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602447: Call_DisableRadius_602435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_602447.validator(path, query, header, formData, body)
  let scheme = call_602447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602447.url(scheme.get, call_602447.host, call_602447.base,
                         call_602447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602447, url, valid)

proc call*(call_602448: Call_DisableRadius_602435; body: JsonNode): Recallable =
  ## disableRadius
  ## Disables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_602449 = newJObject()
  if body != nil:
    body_602449 = body
  result = call_602448.call(nil, nil, nil, nil, body_602449)

var disableRadius* = Call_DisableRadius_602435(name: "disableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.DisableRadius",
    validator: validate_DisableRadius_602436, base: "/", url: url_DisableRadius_602437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSso_602450 = ref object of OpenApiRestCall_601389
proc url_DisableSso_602452(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DisableSso_602451(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables single-sign on for a directory.
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
  var valid_602453 = header.getOrDefault("X-Amz-Target")
  valid_602453 = validateParameter(valid_602453, JString, required = true, default = newJString(
      "DirectoryService_20150416.DisableSso"))
  if valid_602453 != nil:
    section.add "X-Amz-Target", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Signature")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Signature", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Content-Sha256", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Date")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Date", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Credential")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Credential", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Security-Token")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Security-Token", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Algorithm")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Algorithm", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-SignedHeaders", valid_602460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602462: Call_DisableSso_602450; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables single-sign on for a directory.
  ## 
  let valid = call_602462.validator(path, query, header, formData, body)
  let scheme = call_602462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602462.url(scheme.get, call_602462.host, call_602462.base,
                         call_602462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602462, url, valid)

proc call*(call_602463: Call_DisableSso_602450; body: JsonNode): Recallable =
  ## disableSso
  ## Disables single-sign on for a directory.
  ##   body: JObject (required)
  var body_602464 = newJObject()
  if body != nil:
    body_602464 = body
  result = call_602463.call(nil, nil, nil, nil, body_602464)

var disableSso* = Call_DisableSso_602450(name: "disableSso",
                                      meth: HttpMethod.HttpPost,
                                      host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.DisableSso",
                                      validator: validate_DisableSso_602451,
                                      base: "/", url: url_DisableSso_602452,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableLDAPS_602465 = ref object of OpenApiRestCall_601389
proc url_EnableLDAPS_602467(protocol: Scheme; host: string; base: string;
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

proc validate_EnableLDAPS_602466(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Activates the switch for the specific directory to always use LDAP secure calls.
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
  var valid_602468 = header.getOrDefault("X-Amz-Target")
  valid_602468 = validateParameter(valid_602468, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableLDAPS"))
  if valid_602468 != nil:
    section.add "X-Amz-Target", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Signature")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Signature", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Content-Sha256", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Date")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Date", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Credential")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Credential", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Security-Token")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Security-Token", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Algorithm")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Algorithm", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-SignedHeaders", valid_602475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602477: Call_EnableLDAPS_602465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Activates the switch for the specific directory to always use LDAP secure calls.
  ## 
  let valid = call_602477.validator(path, query, header, formData, body)
  let scheme = call_602477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602477.url(scheme.get, call_602477.host, call_602477.base,
                         call_602477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602477, url, valid)

proc call*(call_602478: Call_EnableLDAPS_602465; body: JsonNode): Recallable =
  ## enableLDAPS
  ## Activates the switch for the specific directory to always use LDAP secure calls.
  ##   body: JObject (required)
  var body_602479 = newJObject()
  if body != nil:
    body_602479 = body
  result = call_602478.call(nil, nil, nil, nil, body_602479)

var enableLDAPS* = Call_EnableLDAPS_602465(name: "enableLDAPS",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableLDAPS",
                                        validator: validate_EnableLDAPS_602466,
                                        base: "/", url: url_EnableLDAPS_602467,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableRadius_602480 = ref object of OpenApiRestCall_601389
proc url_EnableRadius_602482(protocol: Scheme; host: string; base: string;
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

proc validate_EnableRadius_602481(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
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
  var valid_602483 = header.getOrDefault("X-Amz-Target")
  valid_602483 = validateParameter(valid_602483, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableRadius"))
  if valid_602483 != nil:
    section.add "X-Amz-Target", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Signature")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Signature", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Content-Sha256", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Date")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Date", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Credential")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Credential", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Security-Token")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Security-Token", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Algorithm")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Algorithm", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-SignedHeaders", valid_602490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602492: Call_EnableRadius_602480; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_602492.validator(path, query, header, formData, body)
  let scheme = call_602492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602492.url(scheme.get, call_602492.host, call_602492.base,
                         call_602492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602492, url, valid)

proc call*(call_602493: Call_EnableRadius_602480; body: JsonNode): Recallable =
  ## enableRadius
  ## Enables multi-factor authentication (MFA) with the Remote Authentication Dial In User Service (RADIUS) server for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_602494 = newJObject()
  if body != nil:
    body_602494 = body
  result = call_602493.call(nil, nil, nil, nil, body_602494)

var enableRadius* = Call_EnableRadius_602480(name: "enableRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.EnableRadius",
    validator: validate_EnableRadius_602481, base: "/", url: url_EnableRadius_602482,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSso_602495 = ref object of OpenApiRestCall_601389
proc url_EnableSso_602497(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_EnableSso_602496(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
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
  var valid_602498 = header.getOrDefault("X-Amz-Target")
  valid_602498 = validateParameter(valid_602498, JString, required = true, default = newJString(
      "DirectoryService_20150416.EnableSso"))
  if valid_602498 != nil:
    section.add "X-Amz-Target", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Signature")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Signature", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Content-Sha256", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Date")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Date", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Credential")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Credential", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Security-Token")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Security-Token", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Algorithm")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Algorithm", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-SignedHeaders", valid_602505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602507: Call_EnableSso_602495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
  ## 
  let valid = call_602507.validator(path, query, header, formData, body)
  let scheme = call_602507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602507.url(scheme.get, call_602507.host, call_602507.base,
                         call_602507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602507, url, valid)

proc call*(call_602508: Call_EnableSso_602495; body: JsonNode): Recallable =
  ## enableSso
  ## Enables single sign-on for a directory. Single sign-on allows users in your directory to access certain AWS services from a computer joined to the directory without having to enter their credentials separately.
  ##   body: JObject (required)
  var body_602509 = newJObject()
  if body != nil:
    body_602509 = body
  result = call_602508.call(nil, nil, nil, nil, body_602509)

var enableSso* = Call_EnableSso_602495(name: "enableSso", meth: HttpMethod.HttpPost,
                                    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.EnableSso",
                                    validator: validate_EnableSso_602496,
                                    base: "/", url: url_EnableSso_602497,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDirectoryLimits_602510 = ref object of OpenApiRestCall_601389
proc url_GetDirectoryLimits_602512(protocol: Scheme; host: string; base: string;
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

proc validate_GetDirectoryLimits_602511(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Obtains directory limit information for the current Region.
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
  var valid_602513 = header.getOrDefault("X-Amz-Target")
  valid_602513 = validateParameter(valid_602513, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetDirectoryLimits"))
  if valid_602513 != nil:
    section.add "X-Amz-Target", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Signature")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Signature", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Content-Sha256", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-Date")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Date", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Credential")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Credential", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Security-Token")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Security-Token", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Algorithm")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Algorithm", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-SignedHeaders", valid_602520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602522: Call_GetDirectoryLimits_602510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains directory limit information for the current Region.
  ## 
  let valid = call_602522.validator(path, query, header, formData, body)
  let scheme = call_602522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602522.url(scheme.get, call_602522.host, call_602522.base,
                         call_602522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602522, url, valid)

proc call*(call_602523: Call_GetDirectoryLimits_602510; body: JsonNode): Recallable =
  ## getDirectoryLimits
  ## Obtains directory limit information for the current Region.
  ##   body: JObject (required)
  var body_602524 = newJObject()
  if body != nil:
    body_602524 = body
  result = call_602523.call(nil, nil, nil, nil, body_602524)

var getDirectoryLimits* = Call_GetDirectoryLimits_602510(
    name: "getDirectoryLimits", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetDirectoryLimits",
    validator: validate_GetDirectoryLimits_602511, base: "/",
    url: url_GetDirectoryLimits_602512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnapshotLimits_602525 = ref object of OpenApiRestCall_601389
proc url_GetSnapshotLimits_602527(protocol: Scheme; host: string; base: string;
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

proc validate_GetSnapshotLimits_602526(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Obtains the manual snapshot limits for a directory.
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
  var valid_602528 = header.getOrDefault("X-Amz-Target")
  valid_602528 = validateParameter(valid_602528, JString, required = true, default = newJString(
      "DirectoryService_20150416.GetSnapshotLimits"))
  if valid_602528 != nil:
    section.add "X-Amz-Target", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Signature")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Signature", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Content-Sha256", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Date")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Date", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Credential")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Credential", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Security-Token")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Security-Token", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Algorithm")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Algorithm", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-SignedHeaders", valid_602535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602537: Call_GetSnapshotLimits_602525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtains the manual snapshot limits for a directory.
  ## 
  let valid = call_602537.validator(path, query, header, formData, body)
  let scheme = call_602537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602537.url(scheme.get, call_602537.host, call_602537.base,
                         call_602537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602537, url, valid)

proc call*(call_602538: Call_GetSnapshotLimits_602525; body: JsonNode): Recallable =
  ## getSnapshotLimits
  ## Obtains the manual snapshot limits for a directory.
  ##   body: JObject (required)
  var body_602539 = newJObject()
  if body != nil:
    body_602539 = body
  result = call_602538.call(nil, nil, nil, nil, body_602539)

var getSnapshotLimits* = Call_GetSnapshotLimits_602525(name: "getSnapshotLimits",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.GetSnapshotLimits",
    validator: validate_GetSnapshotLimits_602526, base: "/",
    url: url_GetSnapshotLimits_602527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCertificates_602540 = ref object of OpenApiRestCall_601389
proc url_ListCertificates_602542(protocol: Scheme; host: string; base: string;
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

proc validate_ListCertificates_602541(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
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
  var valid_602543 = header.getOrDefault("X-Amz-Target")
  valid_602543 = validateParameter(valid_602543, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListCertificates"))
  if valid_602543 != nil:
    section.add "X-Amz-Target", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Signature")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Signature", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Content-Sha256", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Date")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Date", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Credential")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Credential", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Security-Token")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Security-Token", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Algorithm")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Algorithm", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-SignedHeaders", valid_602550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602552: Call_ListCertificates_602540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
  ## 
  let valid = call_602552.validator(path, query, header, formData, body)
  let scheme = call_602552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602552.url(scheme.get, call_602552.host, call_602552.base,
                         call_602552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602552, url, valid)

proc call*(call_602553: Call_ListCertificates_602540; body: JsonNode): Recallable =
  ## listCertificates
  ## For the specified directory, lists all the certificates registered for a secured LDAP connection.
  ##   body: JObject (required)
  var body_602554 = newJObject()
  if body != nil:
    body_602554 = body
  result = call_602553.call(nil, nil, nil, nil, body_602554)

var listCertificates* = Call_ListCertificates_602540(name: "listCertificates",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListCertificates",
    validator: validate_ListCertificates_602541, base: "/",
    url: url_ListCertificates_602542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIpRoutes_602555 = ref object of OpenApiRestCall_601389
proc url_ListIpRoutes_602557(protocol: Scheme; host: string; base: string;
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

proc validate_ListIpRoutes_602556(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the address blocks that you have added to a directory.
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
  var valid_602558 = header.getOrDefault("X-Amz-Target")
  valid_602558 = validateParameter(valid_602558, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListIpRoutes"))
  if valid_602558 != nil:
    section.add "X-Amz-Target", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Signature")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Signature", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Content-Sha256", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Date")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Date", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Credential")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Credential", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Security-Token")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Security-Token", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Algorithm")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Algorithm", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-SignedHeaders", valid_602565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602567: Call_ListIpRoutes_602555; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the address blocks that you have added to a directory.
  ## 
  let valid = call_602567.validator(path, query, header, formData, body)
  let scheme = call_602567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602567.url(scheme.get, call_602567.host, call_602567.base,
                         call_602567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602567, url, valid)

proc call*(call_602568: Call_ListIpRoutes_602555; body: JsonNode): Recallable =
  ## listIpRoutes
  ## Lists the address blocks that you have added to a directory.
  ##   body: JObject (required)
  var body_602569 = newJObject()
  if body != nil:
    body_602569 = body
  result = call_602568.call(nil, nil, nil, nil, body_602569)

var listIpRoutes* = Call_ListIpRoutes_602555(name: "listIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListIpRoutes",
    validator: validate_ListIpRoutes_602556, base: "/", url: url_ListIpRoutes_602557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogSubscriptions_602570 = ref object of OpenApiRestCall_601389
proc url_ListLogSubscriptions_602572(protocol: Scheme; host: string; base: string;
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

proc validate_ListLogSubscriptions_602571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the active log subscriptions for the AWS account.
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
  var valid_602573 = header.getOrDefault("X-Amz-Target")
  valid_602573 = validateParameter(valid_602573, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListLogSubscriptions"))
  if valid_602573 != nil:
    section.add "X-Amz-Target", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Signature")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Signature", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Content-Sha256", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Date")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Date", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Credential")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Credential", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Security-Token")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Security-Token", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Algorithm")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Algorithm", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-SignedHeaders", valid_602580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602582: Call_ListLogSubscriptions_602570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the active log subscriptions for the AWS account.
  ## 
  let valid = call_602582.validator(path, query, header, formData, body)
  let scheme = call_602582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602582.url(scheme.get, call_602582.host, call_602582.base,
                         call_602582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602582, url, valid)

proc call*(call_602583: Call_ListLogSubscriptions_602570; body: JsonNode): Recallable =
  ## listLogSubscriptions
  ## Lists the active log subscriptions for the AWS account.
  ##   body: JObject (required)
  var body_602584 = newJObject()
  if body != nil:
    body_602584 = body
  result = call_602583.call(nil, nil, nil, nil, body_602584)

var listLogSubscriptions* = Call_ListLogSubscriptions_602570(
    name: "listLogSubscriptions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListLogSubscriptions",
    validator: validate_ListLogSubscriptions_602571, base: "/",
    url: url_ListLogSubscriptions_602572, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSchemaExtensions_602585 = ref object of OpenApiRestCall_601389
proc url_ListSchemaExtensions_602587(protocol: Scheme; host: string; base: string;
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

proc validate_ListSchemaExtensions_602586(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all schema extensions applied to a Microsoft AD Directory.
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
  var valid_602588 = header.getOrDefault("X-Amz-Target")
  valid_602588 = validateParameter(valid_602588, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListSchemaExtensions"))
  if valid_602588 != nil:
    section.add "X-Amz-Target", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Signature")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Signature", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Content-Sha256", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Date")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Date", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Credential")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Credential", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Security-Token")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Security-Token", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Algorithm")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Algorithm", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-SignedHeaders", valid_602595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602597: Call_ListSchemaExtensions_602585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ## 
  let valid = call_602597.validator(path, query, header, formData, body)
  let scheme = call_602597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602597.url(scheme.get, call_602597.host, call_602597.base,
                         call_602597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602597, url, valid)

proc call*(call_602598: Call_ListSchemaExtensions_602585; body: JsonNode): Recallable =
  ## listSchemaExtensions
  ## Lists all schema extensions applied to a Microsoft AD Directory.
  ##   body: JObject (required)
  var body_602599 = newJObject()
  if body != nil:
    body_602599 = body
  result = call_602598.call(nil, nil, nil, nil, body_602599)

var listSchemaExtensions* = Call_ListSchemaExtensions_602585(
    name: "listSchemaExtensions", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListSchemaExtensions",
    validator: validate_ListSchemaExtensions_602586, base: "/",
    url: url_ListSchemaExtensions_602587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602600 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602602(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602601(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags on a directory.
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
  var valid_602603 = header.getOrDefault("X-Amz-Target")
  valid_602603 = validateParameter(valid_602603, JString, required = true, default = newJString(
      "DirectoryService_20150416.ListTagsForResource"))
  if valid_602603 != nil:
    section.add "X-Amz-Target", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Signature")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Signature", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Content-Sha256", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Date")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Date", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Credential")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Credential", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Security-Token")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Security-Token", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Algorithm")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Algorithm", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-SignedHeaders", valid_602610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602612: Call_ListTagsForResource_602600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a directory.
  ## 
  let valid = call_602612.validator(path, query, header, formData, body)
  let scheme = call_602612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602612.url(scheme.get, call_602612.host, call_602612.base,
                         call_602612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602612, url, valid)

proc call*(call_602613: Call_ListTagsForResource_602600; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Lists all tags on a directory.
  ##   body: JObject (required)
  var body_602614 = newJObject()
  if body != nil:
    body_602614 = body
  result = call_602613.call(nil, nil, nil, nil, body_602614)

var listTagsForResource* = Call_ListTagsForResource_602600(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ListTagsForResource",
    validator: validate_ListTagsForResource_602601, base: "/",
    url: url_ListTagsForResource_602602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterCertificate_602615 = ref object of OpenApiRestCall_601389
proc url_RegisterCertificate_602617(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterCertificate_602616(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Registers a certificate for secured LDAP connection.
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
  var valid_602618 = header.getOrDefault("X-Amz-Target")
  valid_602618 = validateParameter(valid_602618, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterCertificate"))
  if valid_602618 != nil:
    section.add "X-Amz-Target", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Signature")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Signature", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Content-Sha256", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Date")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Date", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Credential")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Credential", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Security-Token")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Security-Token", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Algorithm")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Algorithm", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-SignedHeaders", valid_602625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602627: Call_RegisterCertificate_602615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a certificate for secured LDAP connection.
  ## 
  let valid = call_602627.validator(path, query, header, formData, body)
  let scheme = call_602627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602627.url(scheme.get, call_602627.host, call_602627.base,
                         call_602627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602627, url, valid)

proc call*(call_602628: Call_RegisterCertificate_602615; body: JsonNode): Recallable =
  ## registerCertificate
  ## Registers a certificate for secured LDAP connection.
  ##   body: JObject (required)
  var body_602629 = newJObject()
  if body != nil:
    body_602629 = body
  result = call_602628.call(nil, nil, nil, nil, body_602629)

var registerCertificate* = Call_RegisterCertificate_602615(
    name: "registerCertificate", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterCertificate",
    validator: validate_RegisterCertificate_602616, base: "/",
    url: url_RegisterCertificate_602617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterEventTopic_602630 = ref object of OpenApiRestCall_601389
proc url_RegisterEventTopic_602632(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterEventTopic_602631(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
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
  var valid_602633 = header.getOrDefault("X-Amz-Target")
  valid_602633 = validateParameter(valid_602633, JString, required = true, default = newJString(
      "DirectoryService_20150416.RegisterEventTopic"))
  if valid_602633 != nil:
    section.add "X-Amz-Target", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Signature")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Signature", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Content-Sha256", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Date")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Date", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Credential")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Credential", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Security-Token")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Security-Token", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Algorithm")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Algorithm", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-SignedHeaders", valid_602640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602642: Call_RegisterEventTopic_602630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ## 
  let valid = call_602642.validator(path, query, header, formData, body)
  let scheme = call_602642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602642.url(scheme.get, call_602642.host, call_602642.base,
                         call_602642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602642, url, valid)

proc call*(call_602643: Call_RegisterEventTopic_602630; body: JsonNode): Recallable =
  ## registerEventTopic
  ## Associates a directory with an SNS topic. This establishes the directory as a publisher to the specified SNS topic. You can then receive email or text (SMS) messages when the status of your directory changes. You get notified if your directory goes from an Active status to an Impaired or Inoperable status. You also receive a notification when the directory returns to an Active status.
  ##   body: JObject (required)
  var body_602644 = newJObject()
  if body != nil:
    body_602644 = body
  result = call_602643.call(nil, nil, nil, nil, body_602644)

var registerEventTopic* = Call_RegisterEventTopic_602630(
    name: "registerEventTopic", meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RegisterEventTopic",
    validator: validate_RegisterEventTopic_602631, base: "/",
    url: url_RegisterEventTopic_602632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RejectSharedDirectory_602645 = ref object of OpenApiRestCall_601389
proc url_RejectSharedDirectory_602647(protocol: Scheme; host: string; base: string;
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

proc validate_RejectSharedDirectory_602646(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rejects a directory sharing request that was sent from the directory owner account.
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
  var valid_602648 = header.getOrDefault("X-Amz-Target")
  valid_602648 = validateParameter(valid_602648, JString, required = true, default = newJString(
      "DirectoryService_20150416.RejectSharedDirectory"))
  if valid_602648 != nil:
    section.add "X-Amz-Target", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Signature")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Signature", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Content-Sha256", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Date")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Date", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Credential")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Credential", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Security-Token")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Security-Token", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Algorithm")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Algorithm", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-SignedHeaders", valid_602655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602657: Call_RejectSharedDirectory_602645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ## 
  let valid = call_602657.validator(path, query, header, formData, body)
  let scheme = call_602657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602657.url(scheme.get, call_602657.host, call_602657.base,
                         call_602657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602657, url, valid)

proc call*(call_602658: Call_RejectSharedDirectory_602645; body: JsonNode): Recallable =
  ## rejectSharedDirectory
  ## Rejects a directory sharing request that was sent from the directory owner account.
  ##   body: JObject (required)
  var body_602659 = newJObject()
  if body != nil:
    body_602659 = body
  result = call_602658.call(nil, nil, nil, nil, body_602659)

var rejectSharedDirectory* = Call_RejectSharedDirectory_602645(
    name: "rejectSharedDirectory", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RejectSharedDirectory",
    validator: validate_RejectSharedDirectory_602646, base: "/",
    url: url_RejectSharedDirectory_602647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveIpRoutes_602660 = ref object of OpenApiRestCall_601389
proc url_RemoveIpRoutes_602662(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveIpRoutes_602661(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Removes IP address blocks from a directory.
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
  var valid_602663 = header.getOrDefault("X-Amz-Target")
  valid_602663 = validateParameter(valid_602663, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveIpRoutes"))
  if valid_602663 != nil:
    section.add "X-Amz-Target", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Signature")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Signature", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Content-Sha256", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Date")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Date", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Credential")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Credential", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Security-Token")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Security-Token", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Algorithm")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Algorithm", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-SignedHeaders", valid_602670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602672: Call_RemoveIpRoutes_602660; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes IP address blocks from a directory.
  ## 
  let valid = call_602672.validator(path, query, header, formData, body)
  let scheme = call_602672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602672.url(scheme.get, call_602672.host, call_602672.base,
                         call_602672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602672, url, valid)

proc call*(call_602673: Call_RemoveIpRoutes_602660; body: JsonNode): Recallable =
  ## removeIpRoutes
  ## Removes IP address blocks from a directory.
  ##   body: JObject (required)
  var body_602674 = newJObject()
  if body != nil:
    body_602674 = body
  result = call_602673.call(nil, nil, nil, nil, body_602674)

var removeIpRoutes* = Call_RemoveIpRoutes_602660(name: "removeIpRoutes",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveIpRoutes",
    validator: validate_RemoveIpRoutes_602661, base: "/", url: url_RemoveIpRoutes_602662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_602675 = ref object of OpenApiRestCall_601389
proc url_RemoveTagsFromResource_602677(protocol: Scheme; host: string; base: string;
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

proc validate_RemoveTagsFromResource_602676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a directory.
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
  var valid_602678 = header.getOrDefault("X-Amz-Target")
  valid_602678 = validateParameter(valid_602678, JString, required = true, default = newJString(
      "DirectoryService_20150416.RemoveTagsFromResource"))
  if valid_602678 != nil:
    section.add "X-Amz-Target", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Signature")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Signature", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-Content-Sha256", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Date")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Date", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Credential")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Credential", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Security-Token")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Security-Token", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Algorithm")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Algorithm", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-SignedHeaders", valid_602685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602687: Call_RemoveTagsFromResource_602675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a directory.
  ## 
  let valid = call_602687.validator(path, query, header, formData, body)
  let scheme = call_602687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602687.url(scheme.get, call_602687.host, call_602687.base,
                         call_602687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602687, url, valid)

proc call*(call_602688: Call_RemoveTagsFromResource_602675; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tags from a directory.
  ##   body: JObject (required)
  var body_602689 = newJObject()
  if body != nil:
    body_602689 = body
  result = call_602688.call(nil, nil, nil, nil, body_602689)

var removeTagsFromResource* = Call_RemoveTagsFromResource_602675(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_602676, base: "/",
    url: url_RemoveTagsFromResource_602677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetUserPassword_602690 = ref object of OpenApiRestCall_601389
proc url_ResetUserPassword_602692(protocol: Scheme; host: string; base: string;
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

proc validate_ResetUserPassword_602691(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
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
  var valid_602693 = header.getOrDefault("X-Amz-Target")
  valid_602693 = validateParameter(valid_602693, JString, required = true, default = newJString(
      "DirectoryService_20150416.ResetUserPassword"))
  if valid_602693 != nil:
    section.add "X-Amz-Target", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Signature")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Signature", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Content-Sha256", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Date")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Date", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Credential")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Credential", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Security-Token")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Security-Token", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Algorithm")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Algorithm", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-SignedHeaders", valid_602700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602702: Call_ResetUserPassword_602690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_602702.validator(path, query, header, formData, body)
  let scheme = call_602702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602702.url(scheme.get, call_602702.host, call_602702.base,
                         call_602702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602702, url, valid)

proc call*(call_602703: Call_ResetUserPassword_602690; body: JsonNode): Recallable =
  ## resetUserPassword
  ## <p>Resets the password for any user in your AWS Managed Microsoft AD or Simple AD directory.</p> <p>You can reset the password for any user in your directory with the following exceptions:</p> <ul> <li> <p>For Simple AD, you cannot reset the password for any user that is a member of either the <b>Domain Admins</b> or <b>Enterprise Admins</b> group except for the administrator user.</p> </li> <li> <p>For AWS Managed Microsoft AD, you can only reset the password for a user that is in an OU based off of the NetBIOS name that you typed when you created your directory. For example, you cannot reset the password for a user in the <b>AWS Reserved</b> OU. For more information about the OU structure for an AWS Managed Microsoft AD directory, see <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_what_gets_created.html">What Gets Created</a> in the <i>AWS Directory Service Administration Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602704 = newJObject()
  if body != nil:
    body_602704 = body
  result = call_602703.call(nil, nil, nil, nil, body_602704)

var resetUserPassword* = Call_ResetUserPassword_602690(name: "resetUserPassword",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ResetUserPassword",
    validator: validate_ResetUserPassword_602691, base: "/",
    url: url_ResetUserPassword_602692, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestoreFromSnapshot_602705 = ref object of OpenApiRestCall_601389
proc url_RestoreFromSnapshot_602707(protocol: Scheme; host: string; base: string;
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

proc validate_RestoreFromSnapshot_602706(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
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
  var valid_602708 = header.getOrDefault("X-Amz-Target")
  valid_602708 = validateParameter(valid_602708, JString, required = true, default = newJString(
      "DirectoryService_20150416.RestoreFromSnapshot"))
  if valid_602708 != nil:
    section.add "X-Amz-Target", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Signature")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Signature", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Content-Sha256", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Date")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Date", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Credential")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Credential", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Security-Token")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Security-Token", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Algorithm")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Algorithm", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-SignedHeaders", valid_602715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602717: Call_RestoreFromSnapshot_602705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ## 
  let valid = call_602717.validator(path, query, header, formData, body)
  let scheme = call_602717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602717.url(scheme.get, call_602717.host, call_602717.base,
                         call_602717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602717, url, valid)

proc call*(call_602718: Call_RestoreFromSnapshot_602705; body: JsonNode): Recallable =
  ## restoreFromSnapshot
  ## <p>Restores a directory using an existing directory snapshot.</p> <p>When you restore a directory from a snapshot, any changes made to the directory after the snapshot date are overwritten.</p> <p>This action returns as soon as the restore operation is initiated. You can monitor the progress of the restore operation by calling the <a>DescribeDirectories</a> operation with the directory identifier. When the <b>DirectoryDescription.Stage</b> value changes to <code>Active</code>, the restore operation is complete.</p>
  ##   body: JObject (required)
  var body_602719 = newJObject()
  if body != nil:
    body_602719 = body
  result = call_602718.call(nil, nil, nil, nil, body_602719)

var restoreFromSnapshot* = Call_RestoreFromSnapshot_602705(
    name: "restoreFromSnapshot", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.RestoreFromSnapshot",
    validator: validate_RestoreFromSnapshot_602706, base: "/",
    url: url_RestoreFromSnapshot_602707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ShareDirectory_602720 = ref object of OpenApiRestCall_601389
proc url_ShareDirectory_602722(protocol: Scheme; host: string; base: string;
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

proc validate_ShareDirectory_602721(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
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
  var valid_602723 = header.getOrDefault("X-Amz-Target")
  valid_602723 = validateParameter(valid_602723, JString, required = true, default = newJString(
      "DirectoryService_20150416.ShareDirectory"))
  if valid_602723 != nil:
    section.add "X-Amz-Target", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Signature")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Signature", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Content-Sha256", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Date")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Date", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Credential")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Credential", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Security-Token")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Security-Token", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Algorithm")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Algorithm", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-SignedHeaders", valid_602730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602732: Call_ShareDirectory_602720; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ## 
  let valid = call_602732.validator(path, query, header, formData, body)
  let scheme = call_602732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602732.url(scheme.get, call_602732.host, call_602732.base,
                         call_602732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602732, url, valid)

proc call*(call_602733: Call_ShareDirectory_602720; body: JsonNode): Recallable =
  ## shareDirectory
  ## <p>Shares a specified directory (<code>DirectoryId</code>) in your AWS account (directory owner) with another AWS account (directory consumer). With this operation you can use your directory from any AWS account and from any Amazon VPC within an AWS Region.</p> <p>When you share your AWS Managed Microsoft AD directory, AWS Directory Service creates a shared directory in the directory consumer account. This shared directory contains the metadata to provide access to the directory within the directory owner account. The shared directory is visible in all VPCs in the directory consumer account.</p> <p>The <code>ShareMethod</code> parameter determines whether the specified directory can be shared between AWS accounts inside the same AWS organization (<code>ORGANIZATIONS</code>). It also determines whether you can share the directory with any other AWS account either inside or outside of the organization (<code>HANDSHAKE</code>).</p> <p>The <code>ShareNotes</code> parameter is only used when <code>HANDSHAKE</code> is called, which sends a directory sharing request to the directory consumer. </p>
  ##   body: JObject (required)
  var body_602734 = newJObject()
  if body != nil:
    body_602734 = body
  result = call_602733.call(nil, nil, nil, nil, body_602734)

var shareDirectory* = Call_ShareDirectory_602720(name: "shareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.ShareDirectory",
    validator: validate_ShareDirectory_602721, base: "/", url: url_ShareDirectory_602722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSchemaExtension_602735 = ref object of OpenApiRestCall_601389
proc url_StartSchemaExtension_602737(protocol: Scheme; host: string; base: string;
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

proc validate_StartSchemaExtension_602736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a schema extension to a Microsoft AD directory.
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
  var valid_602738 = header.getOrDefault("X-Amz-Target")
  valid_602738 = validateParameter(valid_602738, JString, required = true, default = newJString(
      "DirectoryService_20150416.StartSchemaExtension"))
  if valid_602738 != nil:
    section.add "X-Amz-Target", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Signature")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Signature", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Content-Sha256", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Date")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Date", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Credential")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Credential", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Security-Token")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Security-Token", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Algorithm")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Algorithm", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-SignedHeaders", valid_602745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602747: Call_StartSchemaExtension_602735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a schema extension to a Microsoft AD directory.
  ## 
  let valid = call_602747.validator(path, query, header, formData, body)
  let scheme = call_602747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602747.url(scheme.get, call_602747.host, call_602747.base,
                         call_602747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602747, url, valid)

proc call*(call_602748: Call_StartSchemaExtension_602735; body: JsonNode): Recallable =
  ## startSchemaExtension
  ## Applies a schema extension to a Microsoft AD directory.
  ##   body: JObject (required)
  var body_602749 = newJObject()
  if body != nil:
    body_602749 = body
  result = call_602748.call(nil, nil, nil, nil, body_602749)

var startSchemaExtension* = Call_StartSchemaExtension_602735(
    name: "startSchemaExtension", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.StartSchemaExtension",
    validator: validate_StartSchemaExtension_602736, base: "/",
    url: url_StartSchemaExtension_602737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnshareDirectory_602750 = ref object of OpenApiRestCall_601389
proc url_UnshareDirectory_602752(protocol: Scheme; host: string; base: string;
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

proc validate_UnshareDirectory_602751(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Stops the directory sharing between the directory owner and consumer accounts. 
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
  var valid_602753 = header.getOrDefault("X-Amz-Target")
  valid_602753 = validateParameter(valid_602753, JString, required = true, default = newJString(
      "DirectoryService_20150416.UnshareDirectory"))
  if valid_602753 != nil:
    section.add "X-Amz-Target", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Signature")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Signature", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Content-Sha256", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Date")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Date", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Credential")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Credential", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Security-Token")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Security-Token", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Algorithm")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Algorithm", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-SignedHeaders", valid_602760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602762: Call_UnshareDirectory_602750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ## 
  let valid = call_602762.validator(path, query, header, formData, body)
  let scheme = call_602762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602762.url(scheme.get, call_602762.host, call_602762.base,
                         call_602762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602762, url, valid)

proc call*(call_602763: Call_UnshareDirectory_602750; body: JsonNode): Recallable =
  ## unshareDirectory
  ## Stops the directory sharing between the directory owner and consumer accounts. 
  ##   body: JObject (required)
  var body_602764 = newJObject()
  if body != nil:
    body_602764 = body
  result = call_602763.call(nil, nil, nil, nil, body_602764)

var unshareDirectory* = Call_UnshareDirectory_602750(name: "unshareDirectory",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UnshareDirectory",
    validator: validate_UnshareDirectory_602751, base: "/",
    url: url_UnshareDirectory_602752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConditionalForwarder_602765 = ref object of OpenApiRestCall_601389
proc url_UpdateConditionalForwarder_602767(protocol: Scheme; host: string;
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

proc validate_UpdateConditionalForwarder_602766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a conditional forwarder that has been set up for your AWS directory.
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
  var valid_602768 = header.getOrDefault("X-Amz-Target")
  valid_602768 = validateParameter(valid_602768, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateConditionalForwarder"))
  if valid_602768 != nil:
    section.add "X-Amz-Target", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Signature")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Signature", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Content-Sha256", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Date")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Date", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Credential")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Credential", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Security-Token")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Security-Token", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Algorithm")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Algorithm", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-SignedHeaders", valid_602775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602777: Call_UpdateConditionalForwarder_602765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ## 
  let valid = call_602777.validator(path, query, header, formData, body)
  let scheme = call_602777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602777.url(scheme.get, call_602777.host, call_602777.base,
                         call_602777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602777, url, valid)

proc call*(call_602778: Call_UpdateConditionalForwarder_602765; body: JsonNode): Recallable =
  ## updateConditionalForwarder
  ## Updates a conditional forwarder that has been set up for your AWS directory.
  ##   body: JObject (required)
  var body_602779 = newJObject()
  if body != nil:
    body_602779 = body
  result = call_602778.call(nil, nil, nil, nil, body_602779)

var updateConditionalForwarder* = Call_UpdateConditionalForwarder_602765(
    name: "updateConditionalForwarder", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateConditionalForwarder",
    validator: validate_UpdateConditionalForwarder_602766, base: "/",
    url: url_UpdateConditionalForwarder_602767,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNumberOfDomainControllers_602780 = ref object of OpenApiRestCall_601389
proc url_UpdateNumberOfDomainControllers_602782(protocol: Scheme; host: string;
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

proc validate_UpdateNumberOfDomainControllers_602781(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
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
  var valid_602783 = header.getOrDefault("X-Amz-Target")
  valid_602783 = validateParameter(valid_602783, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateNumberOfDomainControllers"))
  if valid_602783 != nil:
    section.add "X-Amz-Target", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Signature")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Signature", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Content-Sha256", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Date")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Date", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Credential")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Credential", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Security-Token")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Security-Token", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Algorithm")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Algorithm", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-SignedHeaders", valid_602790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602792: Call_UpdateNumberOfDomainControllers_602780;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ## 
  let valid = call_602792.validator(path, query, header, formData, body)
  let scheme = call_602792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602792.url(scheme.get, call_602792.host, call_602792.base,
                         call_602792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602792, url, valid)

proc call*(call_602793: Call_UpdateNumberOfDomainControllers_602780; body: JsonNode): Recallable =
  ## updateNumberOfDomainControllers
  ## Adds or removes domain controllers to or from the directory. Based on the difference between current value and new value (provided through this API call), domain controllers will be added or removed. It may take up to 45 minutes for any new domain controllers to become fully active once the requested number of domain controllers is updated. During this time, you cannot make another update request.
  ##   body: JObject (required)
  var body_602794 = newJObject()
  if body != nil:
    body_602794 = body
  result = call_602793.call(nil, nil, nil, nil, body_602794)

var updateNumberOfDomainControllers* = Call_UpdateNumberOfDomainControllers_602780(
    name: "updateNumberOfDomainControllers", meth: HttpMethod.HttpPost,
    host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateNumberOfDomainControllers",
    validator: validate_UpdateNumberOfDomainControllers_602781, base: "/",
    url: url_UpdateNumberOfDomainControllers_602782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRadius_602795 = ref object of OpenApiRestCall_601389
proc url_UpdateRadius_602797(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateRadius_602796(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
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
  var valid_602798 = header.getOrDefault("X-Amz-Target")
  valid_602798 = validateParameter(valid_602798, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateRadius"))
  if valid_602798 != nil:
    section.add "X-Amz-Target", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Signature")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Signature", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Content-Sha256", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Date")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Date", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Credential")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Credential", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Security-Token")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Security-Token", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Algorithm")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Algorithm", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-SignedHeaders", valid_602805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602807: Call_UpdateRadius_602795; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ## 
  let valid = call_602807.validator(path, query, header, formData, body)
  let scheme = call_602807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602807.url(scheme.get, call_602807.host, call_602807.base,
                         call_602807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602807, url, valid)

proc call*(call_602808: Call_UpdateRadius_602795; body: JsonNode): Recallable =
  ## updateRadius
  ## Updates the Remote Authentication Dial In User Service (RADIUS) server information for an AD Connector or Microsoft AD directory.
  ##   body: JObject (required)
  var body_602809 = newJObject()
  if body != nil:
    body_602809 = body
  result = call_602808.call(nil, nil, nil, nil, body_602809)

var updateRadius* = Call_UpdateRadius_602795(name: "updateRadius",
    meth: HttpMethod.HttpPost, host: "ds.amazonaws.com",
    route: "/#X-Amz-Target=DirectoryService_20150416.UpdateRadius",
    validator: validate_UpdateRadius_602796, base: "/", url: url_UpdateRadius_602797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrust_602810 = ref object of OpenApiRestCall_601389
proc url_UpdateTrust_602812(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrust_602811(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
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
  var valid_602813 = header.getOrDefault("X-Amz-Target")
  valid_602813 = validateParameter(valid_602813, JString, required = true, default = newJString(
      "DirectoryService_20150416.UpdateTrust"))
  if valid_602813 != nil:
    section.add "X-Amz-Target", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Signature")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Signature", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Content-Sha256", valid_602815
  var valid_602816 = header.getOrDefault("X-Amz-Date")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-Date", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-Credential")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Credential", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Security-Token")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Security-Token", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Algorithm")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Algorithm", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-SignedHeaders", valid_602820
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602822: Call_UpdateTrust_602810; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ## 
  let valid = call_602822.validator(path, query, header, formData, body)
  let scheme = call_602822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602822.url(scheme.get, call_602822.host, call_602822.base,
                         call_602822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602822, url, valid)

proc call*(call_602823: Call_UpdateTrust_602810; body: JsonNode): Recallable =
  ## updateTrust
  ## Updates the trust that has been set up between your AWS Managed Microsoft AD directory and an on-premises Active Directory.
  ##   body: JObject (required)
  var body_602824 = newJObject()
  if body != nil:
    body_602824 = body
  result = call_602823.call(nil, nil, nil, nil, body_602824)

var updateTrust* = Call_UpdateTrust_602810(name: "updateTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.UpdateTrust",
                                        validator: validate_UpdateTrust_602811,
                                        base: "/", url: url_UpdateTrust_602812,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_VerifyTrust_602825 = ref object of OpenApiRestCall_601389
proc url_VerifyTrust_602827(protocol: Scheme; host: string; base: string;
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

proc validate_VerifyTrust_602826(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
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
  var valid_602828 = header.getOrDefault("X-Amz-Target")
  valid_602828 = validateParameter(valid_602828, JString, required = true, default = newJString(
      "DirectoryService_20150416.VerifyTrust"))
  if valid_602828 != nil:
    section.add "X-Amz-Target", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Signature")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Signature", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Content-Sha256", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Date")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Date", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Credential")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Credential", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Security-Token")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Security-Token", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Algorithm")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Algorithm", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-SignedHeaders", valid_602835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602837: Call_VerifyTrust_602825; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ## 
  let valid = call_602837.validator(path, query, header, formData, body)
  let scheme = call_602837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602837.url(scheme.get, call_602837.host, call_602837.base,
                         call_602837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602837, url, valid)

proc call*(call_602838: Call_VerifyTrust_602825; body: JsonNode): Recallable =
  ## verifyTrust
  ## <p>AWS Directory Service for Microsoft Active Directory allows you to configure and verify trust relationships.</p> <p>This action verifies a trust relationship between your AWS Managed Microsoft AD directory and an external domain.</p>
  ##   body: JObject (required)
  var body_602839 = newJObject()
  if body != nil:
    body_602839 = body
  result = call_602838.call(nil, nil, nil, nil, body_602839)

var verifyTrust* = Call_VerifyTrust_602825(name: "verifyTrust",
                                        meth: HttpMethod.HttpPost,
                                        host: "ds.amazonaws.com", route: "/#X-Amz-Target=DirectoryService_20150416.VerifyTrust",
                                        validator: validate_VerifyTrust_602826,
                                        base: "/", url: url_VerifyTrust_602827,
                                        schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
