
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Glue
## version: 2017-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Glue</fullname> <p>Defines the public endpoint for the AWS Glue service.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/glue/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "glue.ap-northeast-1.amazonaws.com", "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
                           "us-west-2": "glue.us-west-2.amazonaws.com",
                           "eu-west-2": "glue.eu-west-2.amazonaws.com", "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "glue.eu-central-1.amazonaws.com",
                           "us-east-2": "glue.us-east-2.amazonaws.com",
                           "us-east-1": "glue.us-east-1.amazonaws.com", "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "glue.ap-south-1.amazonaws.com",
                           "eu-north-1": "glue.eu-north-1.amazonaws.com", "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
                           "us-west-1": "glue.us-west-1.amazonaws.com",
                           "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "glue.eu-west-3.amazonaws.com",
                           "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "glue.sa-east-1.amazonaws.com",
                           "eu-west-1": "glue.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com", "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "glue.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "glue.ap-southeast-1.amazonaws.com",
      "us-west-2": "glue.us-west-2.amazonaws.com",
      "eu-west-2": "glue.eu-west-2.amazonaws.com",
      "ap-northeast-3": "glue.ap-northeast-3.amazonaws.com",
      "eu-central-1": "glue.eu-central-1.amazonaws.com",
      "us-east-2": "glue.us-east-2.amazonaws.com",
      "us-east-1": "glue.us-east-1.amazonaws.com",
      "cn-northwest-1": "glue.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "glue.ap-south-1.amazonaws.com",
      "eu-north-1": "glue.eu-north-1.amazonaws.com",
      "ap-northeast-2": "glue.ap-northeast-2.amazonaws.com",
      "us-west-1": "glue.us-west-1.amazonaws.com",
      "us-gov-east-1": "glue.us-gov-east-1.amazonaws.com",
      "eu-west-3": "glue.eu-west-3.amazonaws.com",
      "cn-north-1": "glue.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "glue.sa-east-1.amazonaws.com",
      "eu-west-1": "glue.eu-west-1.amazonaws.com",
      "us-gov-west-1": "glue.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "glue.ap-southeast-2.amazonaws.com",
      "ca-central-1": "glue.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "glue"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCreatePartition_601727 = ref object of OpenApiRestCall_601389
proc url_BatchCreatePartition_601729(protocol: Scheme; host: string; base: string;
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

proc validate_BatchCreatePartition_601728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates one or more partitions in a batch operation.
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
      "AWSGlue.BatchCreatePartition"))
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

proc call*(call_601885: Call_BatchCreatePartition_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates one or more partitions in a batch operation.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_BatchCreatePartition_601727; body: JsonNode): Recallable =
  ## batchCreatePartition
  ## Creates one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var batchCreatePartition* = Call_BatchCreatePartition_601727(
    name: "batchCreatePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchCreatePartition",
    validator: validate_BatchCreatePartition_601728, base: "/",
    url: url_BatchCreatePartition_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteConnection_601996 = ref object of OpenApiRestCall_601389
proc url_BatchDeleteConnection_601998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteConnection_601997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a list of connection definitions from the Data Catalog.
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
      "AWSGlue.BatchDeleteConnection"))
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

proc call*(call_602008: Call_BatchDeleteConnection_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_BatchDeleteConnection_601996; body: JsonNode): Recallable =
  ## batchDeleteConnection
  ## Deletes a list of connection definitions from the Data Catalog.
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var batchDeleteConnection* = Call_BatchDeleteConnection_601996(
    name: "batchDeleteConnection", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteConnection",
    validator: validate_BatchDeleteConnection_601997, base: "/",
    url: url_BatchDeleteConnection_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeletePartition_602011 = ref object of OpenApiRestCall_601389
proc url_BatchDeletePartition_602013(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeletePartition_602012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes one or more partitions in a batch operation.
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
      "AWSGlue.BatchDeletePartition"))
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

proc call*(call_602023: Call_BatchDeletePartition_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more partitions in a batch operation.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_BatchDeletePartition_602011; body: JsonNode): Recallable =
  ## batchDeletePartition
  ## Deletes one or more partitions in a batch operation.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var batchDeletePartition* = Call_BatchDeletePartition_602011(
    name: "batchDeletePartition", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeletePartition",
    validator: validate_BatchDeletePartition_602012, base: "/",
    url: url_BatchDeletePartition_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTable_602026 = ref object of OpenApiRestCall_601389
proc url_BatchDeleteTable_602028(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteTable_602027(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
      "AWSGlue.BatchDeleteTable"))
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

proc call*(call_602038: Call_BatchDeleteTable_602026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_BatchDeleteTable_602026; body: JsonNode): Recallable =
  ## batchDeleteTable
  ## <p>Deletes multiple tables at once.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>BatchDeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var batchDeleteTable* = Call_BatchDeleteTable_602026(name: "batchDeleteTable",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTable",
    validator: validate_BatchDeleteTable_602027, base: "/",
    url: url_BatchDeleteTable_602028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteTableVersion_602041 = ref object of OpenApiRestCall_601389
proc url_BatchDeleteTableVersion_602043(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDeleteTableVersion_602042(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified batch of versions of a table.
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
      "AWSGlue.BatchDeleteTableVersion"))
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

proc call*(call_602053: Call_BatchDeleteTableVersion_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified batch of versions of a table.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_BatchDeleteTableVersion_602041; body: JsonNode): Recallable =
  ## batchDeleteTableVersion
  ## Deletes a specified batch of versions of a table.
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var batchDeleteTableVersion* = Call_BatchDeleteTableVersion_602041(
    name: "batchDeleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchDeleteTableVersion",
    validator: validate_BatchDeleteTableVersion_602042, base: "/",
    url: url_BatchDeleteTableVersion_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCrawlers_602056 = ref object of OpenApiRestCall_601389
proc url_BatchGetCrawlers_602058(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetCrawlers_602057(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
      "AWSGlue.BatchGetCrawlers"))
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

proc call*(call_602068: Call_BatchGetCrawlers_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_BatchGetCrawlers_602056; body: JsonNode): Recallable =
  ## batchGetCrawlers
  ## Returns a list of resource metadata for a given list of crawler names. After calling the <code>ListCrawlers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var batchGetCrawlers* = Call_BatchGetCrawlers_602056(name: "batchGetCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetCrawlers",
    validator: validate_BatchGetCrawlers_602057, base: "/",
    url: url_BatchGetCrawlers_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDevEndpoints_602071 = ref object of OpenApiRestCall_601389
proc url_BatchGetDevEndpoints_602073(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetDevEndpoints_602072(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
      "AWSGlue.BatchGetDevEndpoints"))
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

proc call*(call_602083: Call_BatchGetDevEndpoints_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_BatchGetDevEndpoints_602071; body: JsonNode): Recallable =
  ## batchGetDevEndpoints
  ## Returns a list of resource metadata for a given list of development endpoint names. After calling the <code>ListDevEndpoints</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var batchGetDevEndpoints* = Call_BatchGetDevEndpoints_602071(
    name: "batchGetDevEndpoints", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetDevEndpoints",
    validator: validate_BatchGetDevEndpoints_602072, base: "/",
    url: url_BatchGetDevEndpoints_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetJobs_602086 = ref object of OpenApiRestCall_601389
proc url_BatchGetJobs_602088(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetJobs_602087(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
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
  valid_602089 = validateParameter(valid_602089, JString, required = true,
                                 default = newJString("AWSGlue.BatchGetJobs"))
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

proc call*(call_602098: Call_BatchGetJobs_602086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_BatchGetJobs_602086; body: JsonNode): Recallable =
  ## batchGetJobs
  ## Returns a list of resource metadata for a given list of job names. After calling the <code>ListJobs</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags. 
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var batchGetJobs* = Call_BatchGetJobs_602086(name: "batchGetJobs",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetJobs",
    validator: validate_BatchGetJobs_602087, base: "/", url: url_BatchGetJobs_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetPartition_602101 = ref object of OpenApiRestCall_601389
proc url_BatchGetPartition_602103(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetPartition_602102(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves partitions in a batch request.
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
      "AWSGlue.BatchGetPartition"))
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

proc call*(call_602113: Call_BatchGetPartition_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves partitions in a batch request.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_BatchGetPartition_602101; body: JsonNode): Recallable =
  ## batchGetPartition
  ## Retrieves partitions in a batch request.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var batchGetPartition* = Call_BatchGetPartition_602101(name: "batchGetPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetPartition",
    validator: validate_BatchGetPartition_602102, base: "/",
    url: url_BatchGetPartition_602103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetTriggers_602116 = ref object of OpenApiRestCall_601389
proc url_BatchGetTriggers_602118(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetTriggers_602117(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
      "AWSGlue.BatchGetTriggers"))
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

proc call*(call_602128: Call_BatchGetTriggers_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_BatchGetTriggers_602116; body: JsonNode): Recallable =
  ## batchGetTriggers
  ## Returns a list of resource metadata for a given list of trigger names. After calling the <code>ListTriggers</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var batchGetTriggers* = Call_BatchGetTriggers_602116(name: "batchGetTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetTriggers",
    validator: validate_BatchGetTriggers_602117, base: "/",
    url: url_BatchGetTriggers_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetWorkflows_602131 = ref object of OpenApiRestCall_601389
proc url_BatchGetWorkflows_602133(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetWorkflows_602132(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
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
      "AWSGlue.BatchGetWorkflows"))
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

proc call*(call_602143: Call_BatchGetWorkflows_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_BatchGetWorkflows_602131; body: JsonNode): Recallable =
  ## batchGetWorkflows
  ## Returns a list of resource metadata for a given list of workflow names. After calling the <code>ListWorkflows</code> operation, you can call this operation to access the data to which you have been granted permissions. This operation supports all IAM permissions, including permission conditions that uses tags.
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var batchGetWorkflows* = Call_BatchGetWorkflows_602131(name: "batchGetWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchGetWorkflows",
    validator: validate_BatchGetWorkflows_602132, base: "/",
    url: url_BatchGetWorkflows_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchStopJobRun_602146 = ref object of OpenApiRestCall_601389
proc url_BatchStopJobRun_602148(protocol: Scheme; host: string; base: string;
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

proc validate_BatchStopJobRun_602147(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Stops one or more job runs for a specified job definition.
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
      "AWSGlue.BatchStopJobRun"))
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

proc call*(call_602158: Call_BatchStopJobRun_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops one or more job runs for a specified job definition.
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_BatchStopJobRun_602146; body: JsonNode): Recallable =
  ## batchStopJobRun
  ## Stops one or more job runs for a specified job definition.
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var batchStopJobRun* = Call_BatchStopJobRun_602146(name: "batchStopJobRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.BatchStopJobRun",
    validator: validate_BatchStopJobRun_602147, base: "/", url: url_BatchStopJobRun_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMLTaskRun_602161 = ref object of OpenApiRestCall_601389
proc url_CancelMLTaskRun_602163(protocol: Scheme; host: string; base: string;
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

proc validate_CancelMLTaskRun_602162(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
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
      "AWSGlue.CancelMLTaskRun"))
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

proc call*(call_602173: Call_CancelMLTaskRun_602161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_CancelMLTaskRun_602161; body: JsonNode): Recallable =
  ## cancelMLTaskRun
  ## Cancels (stops) a task run. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can cancel a machine learning task run at any time by calling <code>CancelMLTaskRun</code> with a task run's parent transform's <code>TransformID</code> and the task run's <code>TaskRunId</code>. 
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var cancelMLTaskRun* = Call_CancelMLTaskRun_602161(name: "cancelMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CancelMLTaskRun",
    validator: validate_CancelMLTaskRun_602162, base: "/", url: url_CancelMLTaskRun_602163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateClassifier_602176 = ref object of OpenApiRestCall_601389
proc url_CreateClassifier_602178(protocol: Scheme; host: string; base: string;
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

proc validate_CreateClassifier_602177(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
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
      "AWSGlue.CreateClassifier"))
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

proc call*(call_602188: Call_CreateClassifier_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_CreateClassifier_602176; body: JsonNode): Recallable =
  ## createClassifier
  ## Creates a classifier in the user's account. This can be a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field of the request is present.
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var createClassifier* = Call_CreateClassifier_602176(name: "createClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateClassifier",
    validator: validate_CreateClassifier_602177, base: "/",
    url: url_CreateClassifier_602178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConnection_602191 = ref object of OpenApiRestCall_601389
proc url_CreateConnection_602193(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConnection_602192(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a connection definition in the Data Catalog.
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
      "AWSGlue.CreateConnection"))
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

proc call*(call_602203: Call_CreateConnection_602191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a connection definition in the Data Catalog.
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_CreateConnection_602191; body: JsonNode): Recallable =
  ## createConnection
  ## Creates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var createConnection* = Call_CreateConnection_602191(name: "createConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateConnection",
    validator: validate_CreateConnection_602192, base: "/",
    url: url_CreateConnection_602193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCrawler_602206 = ref object of OpenApiRestCall_601389
proc url_CreateCrawler_602208(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCrawler_602207(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
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
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = newJString("AWSGlue.CreateCrawler"))
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

proc call*(call_602218: Call_CreateCrawler_602206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_CreateCrawler_602206; body: JsonNode): Recallable =
  ## createCrawler
  ## Creates a new crawler with specified targets, role, configuration, and optional schedule. At least one crawl target must be specified, in the <code>s3Targets</code> field, the <code>jdbcTargets</code> field, or the <code>DynamoDBTargets</code> field.
  ##   body: JObject (required)
  var body_602220 = newJObject()
  if body != nil:
    body_602220 = body
  result = call_602219.call(nil, nil, nil, nil, body_602220)

var createCrawler* = Call_CreateCrawler_602206(name: "createCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateCrawler",
    validator: validate_CreateCrawler_602207, base: "/", url: url_CreateCrawler_602208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatabase_602221 = ref object of OpenApiRestCall_601389
proc url_CreateDatabase_602223(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDatabase_602222(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new database in a Data Catalog.
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
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = newJString("AWSGlue.CreateDatabase"))
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

proc call*(call_602233: Call_CreateDatabase_602221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new database in a Data Catalog.
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_CreateDatabase_602221; body: JsonNode): Recallable =
  ## createDatabase
  ## Creates a new database in a Data Catalog.
  ##   body: JObject (required)
  var body_602235 = newJObject()
  if body != nil:
    body_602235 = body
  result = call_602234.call(nil, nil, nil, nil, body_602235)

var createDatabase* = Call_CreateDatabase_602221(name: "createDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDatabase",
    validator: validate_CreateDatabase_602222, base: "/", url: url_CreateDatabase_602223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDevEndpoint_602236 = ref object of OpenApiRestCall_601389
proc url_CreateDevEndpoint_602238(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDevEndpoint_602237(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a new development endpoint.
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
      "AWSGlue.CreateDevEndpoint"))
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

proc call*(call_602248: Call_CreateDevEndpoint_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new development endpoint.
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_CreateDevEndpoint_602236; body: JsonNode): Recallable =
  ## createDevEndpoint
  ## Creates a new development endpoint.
  ##   body: JObject (required)
  var body_602250 = newJObject()
  if body != nil:
    body_602250 = body
  result = call_602249.call(nil, nil, nil, nil, body_602250)

var createDevEndpoint* = Call_CreateDevEndpoint_602236(name: "createDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateDevEndpoint",
    validator: validate_CreateDevEndpoint_602237, base: "/",
    url: url_CreateDevEndpoint_602238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_602251 = ref object of OpenApiRestCall_601389
proc url_CreateJob_602253(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_602252(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new job definition.
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
  valid_602254 = validateParameter(valid_602254, JString, required = true,
                                 default = newJString("AWSGlue.CreateJob"))
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

proc call*(call_602263: Call_CreateJob_602251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new job definition.
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_CreateJob_602251; body: JsonNode): Recallable =
  ## createJob
  ## Creates a new job definition.
  ##   body: JObject (required)
  var body_602265 = newJObject()
  if body != nil:
    body_602265 = body
  result = call_602264.call(nil, nil, nil, nil, body_602265)

var createJob* = Call_CreateJob_602251(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.CreateJob",
                                    validator: validate_CreateJob_602252,
                                    base: "/", url: url_CreateJob_602253,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMLTransform_602266 = ref object of OpenApiRestCall_601389
proc url_CreateMLTransform_602268(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMLTransform_602267(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
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
      "AWSGlue.CreateMLTransform"))
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

proc call*(call_602278: Call_CreateMLTransform_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ## 
  let valid = call_602278.validator(path, query, header, formData, body)
  let scheme = call_602278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602278.url(scheme.get, call_602278.host, call_602278.base,
                         call_602278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602278, url, valid)

proc call*(call_602279: Call_CreateMLTransform_602266; body: JsonNode): Recallable =
  ## createMLTransform
  ## <p>Creates an AWS Glue machine learning transform. This operation creates the transform and all the necessary parameters to train it.</p> <p>Call this operation as the first step in the process of using a machine learning transform (such as the <code>FindMatches</code> transform) for deduplicating data. You can provide an optional <code>Description</code>, in addition to the parameters that you want to use for your algorithm.</p> <p>You must also specify certain parameters for the tasks that AWS Glue runs on your behalf as part of learning from your data and creating a high-quality machine learning transform. These parameters include <code>Role</code>, and optionally, <code>AllocatedCapacity</code>, <code>Timeout</code>, and <code>MaxRetries</code>. For more information, see <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html">Jobs</a>.</p>
  ##   body: JObject (required)
  var body_602280 = newJObject()
  if body != nil:
    body_602280 = body
  result = call_602279.call(nil, nil, nil, nil, body_602280)

var createMLTransform* = Call_CreateMLTransform_602266(name: "createMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateMLTransform",
    validator: validate_CreateMLTransform_602267, base: "/",
    url: url_CreateMLTransform_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePartition_602281 = ref object of OpenApiRestCall_601389
proc url_CreatePartition_602283(protocol: Scheme; host: string; base: string;
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

proc validate_CreatePartition_602282(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new partition.
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
      "AWSGlue.CreatePartition"))
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

proc call*(call_602293: Call_CreatePartition_602281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new partition.
  ## 
  let valid = call_602293.validator(path, query, header, formData, body)
  let scheme = call_602293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602293.url(scheme.get, call_602293.host, call_602293.base,
                         call_602293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602293, url, valid)

proc call*(call_602294: Call_CreatePartition_602281; body: JsonNode): Recallable =
  ## createPartition
  ## Creates a new partition.
  ##   body: JObject (required)
  var body_602295 = newJObject()
  if body != nil:
    body_602295 = body
  result = call_602294.call(nil, nil, nil, nil, body_602295)

var createPartition* = Call_CreatePartition_602281(name: "createPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreatePartition",
    validator: validate_CreatePartition_602282, base: "/", url: url_CreatePartition_602283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateScript_602296 = ref object of OpenApiRestCall_601389
proc url_CreateScript_602298(protocol: Scheme; host: string; base: string;
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

proc validate_CreateScript_602297(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Transforms a directed acyclic graph (DAG) into code.
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
  valid_602299 = validateParameter(valid_602299, JString, required = true,
                                 default = newJString("AWSGlue.CreateScript"))
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

proc call*(call_602308: Call_CreateScript_602296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a directed acyclic graph (DAG) into code.
  ## 
  let valid = call_602308.validator(path, query, header, formData, body)
  let scheme = call_602308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602308.url(scheme.get, call_602308.host, call_602308.base,
                         call_602308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602308, url, valid)

proc call*(call_602309: Call_CreateScript_602296; body: JsonNode): Recallable =
  ## createScript
  ## Transforms a directed acyclic graph (DAG) into code.
  ##   body: JObject (required)
  var body_602310 = newJObject()
  if body != nil:
    body_602310 = body
  result = call_602309.call(nil, nil, nil, nil, body_602310)

var createScript* = Call_CreateScript_602296(name: "createScript",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateScript",
    validator: validate_CreateScript_602297, base: "/", url: url_CreateScript_602298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_602311 = ref object of OpenApiRestCall_601389
proc url_CreateSecurityConfiguration_602313(protocol: Scheme; host: string;
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

proc validate_CreateSecurityConfiguration_602312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
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
      "AWSGlue.CreateSecurityConfiguration"))
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

proc call*(call_602323: Call_CreateSecurityConfiguration_602311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ## 
  let valid = call_602323.validator(path, query, header, formData, body)
  let scheme = call_602323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602323.url(scheme.get, call_602323.host, call_602323.base,
                         call_602323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602323, url, valid)

proc call*(call_602324: Call_CreateSecurityConfiguration_602311; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a new security configuration. A security configuration is a set of security properties that can be used by AWS Glue. You can use a security configuration to encrypt data at rest. For information about using security configurations in AWS Glue, see <a href="https://docs.aws.amazon.com/glue/latest/dg/encryption-security-configuration.html">Encrypting Data Written by Crawlers, Jobs, and Development Endpoints</a>.
  ##   body: JObject (required)
  var body_602325 = newJObject()
  if body != nil:
    body_602325 = body
  result = call_602324.call(nil, nil, nil, nil, body_602325)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_602311(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_602312, base: "/",
    url: url_CreateSecurityConfiguration_602313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTable_602326 = ref object of OpenApiRestCall_601389
proc url_CreateTable_602328(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTable_602327(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new table definition in the Data Catalog.
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
  var valid_602329 = header.getOrDefault("X-Amz-Target")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = newJString("AWSGlue.CreateTable"))
  if valid_602329 != nil:
    section.add "X-Amz-Target", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_CreateTable_602326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new table definition in the Data Catalog.
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_CreateTable_602326; body: JsonNode): Recallable =
  ## createTable
  ## Creates a new table definition in the Data Catalog.
  ##   body: JObject (required)
  var body_602340 = newJObject()
  if body != nil:
    body_602340 = body
  result = call_602339.call(nil, nil, nil, nil, body_602340)

var createTable* = Call_CreateTable_602326(name: "createTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.CreateTable",
                                        validator: validate_CreateTable_602327,
                                        base: "/", url: url_CreateTable_602328,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrigger_602341 = ref object of OpenApiRestCall_601389
proc url_CreateTrigger_602343(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrigger_602342(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new trigger.
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
  var valid_602344 = header.getOrDefault("X-Amz-Target")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = newJString("AWSGlue.CreateTrigger"))
  if valid_602344 != nil:
    section.add "X-Amz-Target", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Signature")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Signature", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Content-Sha256", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Date")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Date", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Credential")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Credential", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Security-Token")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Security-Token", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Algorithm")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Algorithm", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-SignedHeaders", valid_602351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602353: Call_CreateTrigger_602341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new trigger.
  ## 
  let valid = call_602353.validator(path, query, header, formData, body)
  let scheme = call_602353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602353.url(scheme.get, call_602353.host, call_602353.base,
                         call_602353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602353, url, valid)

proc call*(call_602354: Call_CreateTrigger_602341; body: JsonNode): Recallable =
  ## createTrigger
  ## Creates a new trigger.
  ##   body: JObject (required)
  var body_602355 = newJObject()
  if body != nil:
    body_602355 = body
  result = call_602354.call(nil, nil, nil, nil, body_602355)

var createTrigger* = Call_CreateTrigger_602341(name: "createTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateTrigger",
    validator: validate_CreateTrigger_602342, base: "/", url: url_CreateTrigger_602343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUserDefinedFunction_602356 = ref object of OpenApiRestCall_601389
proc url_CreateUserDefinedFunction_602358(protocol: Scheme; host: string;
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

proc validate_CreateUserDefinedFunction_602357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new function definition in the Data Catalog.
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
  var valid_602359 = header.getOrDefault("X-Amz-Target")
  valid_602359 = validateParameter(valid_602359, JString, required = true, default = newJString(
      "AWSGlue.CreateUserDefinedFunction"))
  if valid_602359 != nil:
    section.add "X-Amz-Target", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Signature")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Signature", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Content-Sha256", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Date")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Date", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Credential")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Credential", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Security-Token")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Security-Token", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Algorithm")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Algorithm", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-SignedHeaders", valid_602366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602368: Call_CreateUserDefinedFunction_602356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new function definition in the Data Catalog.
  ## 
  let valid = call_602368.validator(path, query, header, formData, body)
  let scheme = call_602368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602368.url(scheme.get, call_602368.host, call_602368.base,
                         call_602368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602368, url, valid)

proc call*(call_602369: Call_CreateUserDefinedFunction_602356; body: JsonNode): Recallable =
  ## createUserDefinedFunction
  ## Creates a new function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_602370 = newJObject()
  if body != nil:
    body_602370 = body
  result = call_602369.call(nil, nil, nil, nil, body_602370)

var createUserDefinedFunction* = Call_CreateUserDefinedFunction_602356(
    name: "createUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateUserDefinedFunction",
    validator: validate_CreateUserDefinedFunction_602357, base: "/",
    url: url_CreateUserDefinedFunction_602358,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWorkflow_602371 = ref object of OpenApiRestCall_601389
proc url_CreateWorkflow_602373(protocol: Scheme; host: string; base: string;
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

proc validate_CreateWorkflow_602372(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a new workflow.
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
  var valid_602374 = header.getOrDefault("X-Amz-Target")
  valid_602374 = validateParameter(valid_602374, JString, required = true,
                                 default = newJString("AWSGlue.CreateWorkflow"))
  if valid_602374 != nil:
    section.add "X-Amz-Target", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Signature")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Signature", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Content-Sha256", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Date")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Date", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Credential")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Credential", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Security-Token")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Security-Token", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Algorithm")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Algorithm", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-SignedHeaders", valid_602381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602383: Call_CreateWorkflow_602371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new workflow.
  ## 
  let valid = call_602383.validator(path, query, header, formData, body)
  let scheme = call_602383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602383.url(scheme.get, call_602383.host, call_602383.base,
                         call_602383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602383, url, valid)

proc call*(call_602384: Call_CreateWorkflow_602371; body: JsonNode): Recallable =
  ## createWorkflow
  ## Creates a new workflow.
  ##   body: JObject (required)
  var body_602385 = newJObject()
  if body != nil:
    body_602385 = body
  result = call_602384.call(nil, nil, nil, nil, body_602385)

var createWorkflow* = Call_CreateWorkflow_602371(name: "createWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.CreateWorkflow",
    validator: validate_CreateWorkflow_602372, base: "/", url: url_CreateWorkflow_602373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteClassifier_602386 = ref object of OpenApiRestCall_601389
proc url_DeleteClassifier_602388(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteClassifier_602387(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes a classifier from the Data Catalog.
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
  var valid_602389 = header.getOrDefault("X-Amz-Target")
  valid_602389 = validateParameter(valid_602389, JString, required = true, default = newJString(
      "AWSGlue.DeleteClassifier"))
  if valid_602389 != nil:
    section.add "X-Amz-Target", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Signature")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Signature", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Content-Sha256", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Date")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Date", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Credential")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Credential", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Security-Token")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Security-Token", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Algorithm")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Algorithm", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-SignedHeaders", valid_602396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602398: Call_DeleteClassifier_602386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a classifier from the Data Catalog.
  ## 
  let valid = call_602398.validator(path, query, header, formData, body)
  let scheme = call_602398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602398.url(scheme.get, call_602398.host, call_602398.base,
                         call_602398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602398, url, valid)

proc call*(call_602399: Call_DeleteClassifier_602386; body: JsonNode): Recallable =
  ## deleteClassifier
  ## Removes a classifier from the Data Catalog.
  ##   body: JObject (required)
  var body_602400 = newJObject()
  if body != nil:
    body_602400 = body
  result = call_602399.call(nil, nil, nil, nil, body_602400)

var deleteClassifier* = Call_DeleteClassifier_602386(name: "deleteClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteClassifier",
    validator: validate_DeleteClassifier_602387, base: "/",
    url: url_DeleteClassifier_602388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConnection_602401 = ref object of OpenApiRestCall_601389
proc url_DeleteConnection_602403(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteConnection_602402(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes a connection from the Data Catalog.
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
  var valid_602404 = header.getOrDefault("X-Amz-Target")
  valid_602404 = validateParameter(valid_602404, JString, required = true, default = newJString(
      "AWSGlue.DeleteConnection"))
  if valid_602404 != nil:
    section.add "X-Amz-Target", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Signature")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Signature", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Content-Sha256", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Date")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Date", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Credential")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Credential", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Security-Token")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Security-Token", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Algorithm")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Algorithm", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-SignedHeaders", valid_602411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602413: Call_DeleteConnection_602401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a connection from the Data Catalog.
  ## 
  let valid = call_602413.validator(path, query, header, formData, body)
  let scheme = call_602413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602413.url(scheme.get, call_602413.host, call_602413.base,
                         call_602413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602413, url, valid)

proc call*(call_602414: Call_DeleteConnection_602401; body: JsonNode): Recallable =
  ## deleteConnection
  ## Deletes a connection from the Data Catalog.
  ##   body: JObject (required)
  var body_602415 = newJObject()
  if body != nil:
    body_602415 = body
  result = call_602414.call(nil, nil, nil, nil, body_602415)

var deleteConnection* = Call_DeleteConnection_602401(name: "deleteConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteConnection",
    validator: validate_DeleteConnection_602402, base: "/",
    url: url_DeleteConnection_602403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCrawler_602416 = ref object of OpenApiRestCall_601389
proc url_DeleteCrawler_602418(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCrawler_602417(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
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
  var valid_602419 = header.getOrDefault("X-Amz-Target")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = newJString("AWSGlue.DeleteCrawler"))
  if valid_602419 != nil:
    section.add "X-Amz-Target", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Signature")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Signature", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Content-Sha256", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Date")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Date", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Credential")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Credential", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Algorithm")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Algorithm", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-SignedHeaders", valid_602426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602428: Call_DeleteCrawler_602416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ## 
  let valid = call_602428.validator(path, query, header, formData, body)
  let scheme = call_602428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602428.url(scheme.get, call_602428.host, call_602428.base,
                         call_602428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602428, url, valid)

proc call*(call_602429: Call_DeleteCrawler_602416; body: JsonNode): Recallable =
  ## deleteCrawler
  ## Removes a specified crawler from the AWS Glue Data Catalog, unless the crawler state is <code>RUNNING</code>.
  ##   body: JObject (required)
  var body_602430 = newJObject()
  if body != nil:
    body_602430 = body
  result = call_602429.call(nil, nil, nil, nil, body_602430)

var deleteCrawler* = Call_DeleteCrawler_602416(name: "deleteCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteCrawler",
    validator: validate_DeleteCrawler_602417, base: "/", url: url_DeleteCrawler_602418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatabase_602431 = ref object of OpenApiRestCall_601389
proc url_DeleteDatabase_602433(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDatabase_602432(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
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
  var valid_602434 = header.getOrDefault("X-Amz-Target")
  valid_602434 = validateParameter(valid_602434, JString, required = true,
                                 default = newJString("AWSGlue.DeleteDatabase"))
  if valid_602434 != nil:
    section.add "X-Amz-Target", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Signature")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Signature", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Content-Sha256", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Date")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Date", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Credential")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Credential", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Security-Token")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Security-Token", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Algorithm")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Algorithm", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-SignedHeaders", valid_602441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602443: Call_DeleteDatabase_602431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ## 
  let valid = call_602443.validator(path, query, header, formData, body)
  let scheme = call_602443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602443.url(scheme.get, call_602443.host, call_602443.base,
                         call_602443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602443, url, valid)

proc call*(call_602444: Call_DeleteDatabase_602431; body: JsonNode): Recallable =
  ## deleteDatabase
  ## <p>Removes a specified database from a Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the tables (and all table versions and partitions that might belong to the tables) and the user-defined functions in the deleted database. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteDatabase</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, <code>DeletePartition</code> or <code>BatchDeletePartition</code>, <code>DeleteUserDefinedFunction</code>, and <code>DeleteTable</code> or <code>BatchDeleteTable</code>, to delete any resources that belong to the database.</p> </note>
  ##   body: JObject (required)
  var body_602445 = newJObject()
  if body != nil:
    body_602445 = body
  result = call_602444.call(nil, nil, nil, nil, body_602445)

var deleteDatabase* = Call_DeleteDatabase_602431(name: "deleteDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDatabase",
    validator: validate_DeleteDatabase_602432, base: "/", url: url_DeleteDatabase_602433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDevEndpoint_602446 = ref object of OpenApiRestCall_601389
proc url_DeleteDevEndpoint_602448(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDevEndpoint_602447(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes a specified development endpoint.
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
  var valid_602449 = header.getOrDefault("X-Amz-Target")
  valid_602449 = validateParameter(valid_602449, JString, required = true, default = newJString(
      "AWSGlue.DeleteDevEndpoint"))
  if valid_602449 != nil:
    section.add "X-Amz-Target", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Signature")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Signature", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Content-Sha256", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Date")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Date", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Credential")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Credential", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Security-Token")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Security-Token", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-SignedHeaders", valid_602456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602458: Call_DeleteDevEndpoint_602446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified development endpoint.
  ## 
  let valid = call_602458.validator(path, query, header, formData, body)
  let scheme = call_602458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602458.url(scheme.get, call_602458.host, call_602458.base,
                         call_602458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602458, url, valid)

proc call*(call_602459: Call_DeleteDevEndpoint_602446; body: JsonNode): Recallable =
  ## deleteDevEndpoint
  ## Deletes a specified development endpoint.
  ##   body: JObject (required)
  var body_602460 = newJObject()
  if body != nil:
    body_602460 = body
  result = call_602459.call(nil, nil, nil, nil, body_602460)

var deleteDevEndpoint* = Call_DeleteDevEndpoint_602446(name: "deleteDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteDevEndpoint",
    validator: validate_DeleteDevEndpoint_602447, base: "/",
    url: url_DeleteDevEndpoint_602448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJob_602461 = ref object of OpenApiRestCall_601389
proc url_DeleteJob_602463(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteJob_602462(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
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
  var valid_602464 = header.getOrDefault("X-Amz-Target")
  valid_602464 = validateParameter(valid_602464, JString, required = true,
                                 default = newJString("AWSGlue.DeleteJob"))
  if valid_602464 != nil:
    section.add "X-Amz-Target", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Signature")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Signature", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Content-Sha256", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Date")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Date", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Credential")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Credential", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Security-Token")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Security-Token", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-SignedHeaders", valid_602471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602473: Call_DeleteJob_602461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ## 
  let valid = call_602473.validator(path, query, header, formData, body)
  let scheme = call_602473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602473.url(scheme.get, call_602473.host, call_602473.base,
                         call_602473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602473, url, valid)

proc call*(call_602474: Call_DeleteJob_602461; body: JsonNode): Recallable =
  ## deleteJob
  ## Deletes a specified job definition. If the job definition is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_602475 = newJObject()
  if body != nil:
    body_602475 = body
  result = call_602474.call(nil, nil, nil, nil, body_602475)

var deleteJob* = Call_DeleteJob_602461(name: "deleteJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.DeleteJob",
                                    validator: validate_DeleteJob_602462,
                                    base: "/", url: url_DeleteJob_602463,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMLTransform_602476 = ref object of OpenApiRestCall_601389
proc url_DeleteMLTransform_602478(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMLTransform_602477(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
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
  var valid_602479 = header.getOrDefault("X-Amz-Target")
  valid_602479 = validateParameter(valid_602479, JString, required = true, default = newJString(
      "AWSGlue.DeleteMLTransform"))
  if valid_602479 != nil:
    section.add "X-Amz-Target", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Signature")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Signature", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Content-Sha256", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Date")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Date", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Credential")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Credential", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Security-Token")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Security-Token", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Algorithm")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Algorithm", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-SignedHeaders", valid_602486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602488: Call_DeleteMLTransform_602476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ## 
  let valid = call_602488.validator(path, query, header, formData, body)
  let scheme = call_602488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602488.url(scheme.get, call_602488.host, call_602488.base,
                         call_602488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602488, url, valid)

proc call*(call_602489: Call_DeleteMLTransform_602476; body: JsonNode): Recallable =
  ## deleteMLTransform
  ## Deletes an AWS Glue machine learning transform. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. If you no longer need a transform, you can delete it by calling <code>DeleteMLTransforms</code>. However, any AWS Glue jobs that still reference the deleted transform will no longer succeed.
  ##   body: JObject (required)
  var body_602490 = newJObject()
  if body != nil:
    body_602490 = body
  result = call_602489.call(nil, nil, nil, nil, body_602490)

var deleteMLTransform* = Call_DeleteMLTransform_602476(name: "deleteMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteMLTransform",
    validator: validate_DeleteMLTransform_602477, base: "/",
    url: url_DeleteMLTransform_602478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePartition_602491 = ref object of OpenApiRestCall_601389
proc url_DeletePartition_602493(protocol: Scheme; host: string; base: string;
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

proc validate_DeletePartition_602492(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a specified partition.
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
  var valid_602494 = header.getOrDefault("X-Amz-Target")
  valid_602494 = validateParameter(valid_602494, JString, required = true, default = newJString(
      "AWSGlue.DeletePartition"))
  if valid_602494 != nil:
    section.add "X-Amz-Target", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Signature")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Signature", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Content-Sha256", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Date")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Date", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Credential")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Credential", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Security-Token")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Security-Token", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Algorithm")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Algorithm", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-SignedHeaders", valid_602501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602503: Call_DeletePartition_602491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified partition.
  ## 
  let valid = call_602503.validator(path, query, header, formData, body)
  let scheme = call_602503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602503.url(scheme.get, call_602503.host, call_602503.base,
                         call_602503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602503, url, valid)

proc call*(call_602504: Call_DeletePartition_602491; body: JsonNode): Recallable =
  ## deletePartition
  ## Deletes a specified partition.
  ##   body: JObject (required)
  var body_602505 = newJObject()
  if body != nil:
    body_602505 = body
  result = call_602504.call(nil, nil, nil, nil, body_602505)

var deletePartition* = Call_DeletePartition_602491(name: "deletePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeletePartition",
    validator: validate_DeletePartition_602492, base: "/", url: url_DeletePartition_602493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourcePolicy_602506 = ref object of OpenApiRestCall_601389
proc url_DeleteResourcePolicy_602508(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteResourcePolicy_602507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified policy.
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
  var valid_602509 = header.getOrDefault("X-Amz-Target")
  valid_602509 = validateParameter(valid_602509, JString, required = true, default = newJString(
      "AWSGlue.DeleteResourcePolicy"))
  if valid_602509 != nil:
    section.add "X-Amz-Target", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Signature")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Signature", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Content-Sha256", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Date")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Date", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Credential")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Credential", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Security-Token")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Security-Token", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Algorithm")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Algorithm", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-SignedHeaders", valid_602516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602518: Call_DeleteResourcePolicy_602506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified policy.
  ## 
  let valid = call_602518.validator(path, query, header, formData, body)
  let scheme = call_602518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602518.url(scheme.get, call_602518.host, call_602518.base,
                         call_602518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602518, url, valid)

proc call*(call_602519: Call_DeleteResourcePolicy_602506; body: JsonNode): Recallable =
  ## deleteResourcePolicy
  ## Deletes a specified policy.
  ##   body: JObject (required)
  var body_602520 = newJObject()
  if body != nil:
    body_602520 = body
  result = call_602519.call(nil, nil, nil, nil, body_602520)

var deleteResourcePolicy* = Call_DeleteResourcePolicy_602506(
    name: "deleteResourcePolicy", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteResourcePolicy",
    validator: validate_DeleteResourcePolicy_602507, base: "/",
    url: url_DeleteResourcePolicy_602508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_602521 = ref object of OpenApiRestCall_601389
proc url_DeleteSecurityConfiguration_602523(protocol: Scheme; host: string;
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

proc validate_DeleteSecurityConfiguration_602522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified security configuration.
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
  var valid_602524 = header.getOrDefault("X-Amz-Target")
  valid_602524 = validateParameter(valid_602524, JString, required = true, default = newJString(
      "AWSGlue.DeleteSecurityConfiguration"))
  if valid_602524 != nil:
    section.add "X-Amz-Target", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Signature")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Signature", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Content-Sha256", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Date")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Date", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Credential")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Credential", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Security-Token")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Security-Token", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Algorithm")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Algorithm", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-SignedHeaders", valid_602531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602533: Call_DeleteSecurityConfiguration_602521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified security configuration.
  ## 
  let valid = call_602533.validator(path, query, header, formData, body)
  let scheme = call_602533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602533.url(scheme.get, call_602533.host, call_602533.base,
                         call_602533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602533, url, valid)

proc call*(call_602534: Call_DeleteSecurityConfiguration_602521; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a specified security configuration.
  ##   body: JObject (required)
  var body_602535 = newJObject()
  if body != nil:
    body_602535 = body
  result = call_602534.call(nil, nil, nil, nil, body_602535)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_602521(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_602522, base: "/",
    url: url_DeleteSecurityConfiguration_602523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTable_602536 = ref object of OpenApiRestCall_601389
proc url_DeleteTable_602538(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTable_602537(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
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
  var valid_602539 = header.getOrDefault("X-Amz-Target")
  valid_602539 = validateParameter(valid_602539, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTable"))
  if valid_602539 != nil:
    section.add "X-Amz-Target", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Signature")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Signature", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Content-Sha256", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Date")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Date", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Credential")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Credential", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Security-Token")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Security-Token", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Algorithm")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Algorithm", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-SignedHeaders", valid_602546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602548: Call_DeleteTable_602536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ## 
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_DeleteTable_602536; body: JsonNode): Recallable =
  ## deleteTable
  ## <p>Removes a table definition from the Data Catalog.</p> <note> <p>After completing this operation, you no longer have access to the table versions and partitions that belong to the deleted table. AWS Glue deletes these "orphaned" resources asynchronously in a timely manner, at the discretion of the service.</p> <p>To ensure the immediate deletion of all related resources, before calling <code>DeleteTable</code>, use <code>DeleteTableVersion</code> or <code>BatchDeleteTableVersion</code>, and <code>DeletePartition</code> or <code>BatchDeletePartition</code>, to delete any resources that belong to the table.</p> </note>
  ##   body: JObject (required)
  var body_602550 = newJObject()
  if body != nil:
    body_602550 = body
  result = call_602549.call(nil, nil, nil, nil, body_602550)

var deleteTable* = Call_DeleteTable_602536(name: "deleteTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.DeleteTable",
                                        validator: validate_DeleteTable_602537,
                                        base: "/", url: url_DeleteTable_602538,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTableVersion_602551 = ref object of OpenApiRestCall_601389
proc url_DeleteTableVersion_602553(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTableVersion_602552(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a specified version of a table.
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
  var valid_602554 = header.getOrDefault("X-Amz-Target")
  valid_602554 = validateParameter(valid_602554, JString, required = true, default = newJString(
      "AWSGlue.DeleteTableVersion"))
  if valid_602554 != nil:
    section.add "X-Amz-Target", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Signature")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Signature", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Content-Sha256", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Date")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Date", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Credential")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Credential", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Security-Token")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Security-Token", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Algorithm")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Algorithm", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-SignedHeaders", valid_602561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602563: Call_DeleteTableVersion_602551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified version of a table.
  ## 
  let valid = call_602563.validator(path, query, header, formData, body)
  let scheme = call_602563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602563.url(scheme.get, call_602563.host, call_602563.base,
                         call_602563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602563, url, valid)

proc call*(call_602564: Call_DeleteTableVersion_602551; body: JsonNode): Recallable =
  ## deleteTableVersion
  ## Deletes a specified version of a table.
  ##   body: JObject (required)
  var body_602565 = newJObject()
  if body != nil:
    body_602565 = body
  result = call_602564.call(nil, nil, nil, nil, body_602565)

var deleteTableVersion* = Call_DeleteTableVersion_602551(
    name: "deleteTableVersion", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTableVersion",
    validator: validate_DeleteTableVersion_602552, base: "/",
    url: url_DeleteTableVersion_602553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrigger_602566 = ref object of OpenApiRestCall_601389
proc url_DeleteTrigger_602568(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrigger_602567(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
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
  var valid_602569 = header.getOrDefault("X-Amz-Target")
  valid_602569 = validateParameter(valid_602569, JString, required = true,
                                 default = newJString("AWSGlue.DeleteTrigger"))
  if valid_602569 != nil:
    section.add "X-Amz-Target", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-Signature")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-Signature", valid_602570
  var valid_602571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "X-Amz-Content-Sha256", valid_602571
  var valid_602572 = header.getOrDefault("X-Amz-Date")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Date", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Credential")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Credential", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Security-Token")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Security-Token", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Algorithm")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Algorithm", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-SignedHeaders", valid_602576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602578: Call_DeleteTrigger_602566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ## 
  let valid = call_602578.validator(path, query, header, formData, body)
  let scheme = call_602578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602578.url(scheme.get, call_602578.host, call_602578.base,
                         call_602578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602578, url, valid)

proc call*(call_602579: Call_DeleteTrigger_602566; body: JsonNode): Recallable =
  ## deleteTrigger
  ## Deletes a specified trigger. If the trigger is not found, no exception is thrown.
  ##   body: JObject (required)
  var body_602580 = newJObject()
  if body != nil:
    body_602580 = body
  result = call_602579.call(nil, nil, nil, nil, body_602580)

var deleteTrigger* = Call_DeleteTrigger_602566(name: "deleteTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteTrigger",
    validator: validate_DeleteTrigger_602567, base: "/", url: url_DeleteTrigger_602568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserDefinedFunction_602581 = ref object of OpenApiRestCall_601389
proc url_DeleteUserDefinedFunction_602583(protocol: Scheme; host: string;
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

proc validate_DeleteUserDefinedFunction_602582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing function definition from the Data Catalog.
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
  var valid_602584 = header.getOrDefault("X-Amz-Target")
  valid_602584 = validateParameter(valid_602584, JString, required = true, default = newJString(
      "AWSGlue.DeleteUserDefinedFunction"))
  if valid_602584 != nil:
    section.add "X-Amz-Target", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Signature")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Signature", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Content-Sha256", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Date")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Date", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Credential")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Credential", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Security-Token")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Security-Token", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Algorithm")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Algorithm", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-SignedHeaders", valid_602591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602593: Call_DeleteUserDefinedFunction_602581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing function definition from the Data Catalog.
  ## 
  let valid = call_602593.validator(path, query, header, formData, body)
  let scheme = call_602593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602593.url(scheme.get, call_602593.host, call_602593.base,
                         call_602593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602593, url, valid)

proc call*(call_602594: Call_DeleteUserDefinedFunction_602581; body: JsonNode): Recallable =
  ## deleteUserDefinedFunction
  ## Deletes an existing function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_602595 = newJObject()
  if body != nil:
    body_602595 = body
  result = call_602594.call(nil, nil, nil, nil, body_602595)

var deleteUserDefinedFunction* = Call_DeleteUserDefinedFunction_602581(
    name: "deleteUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteUserDefinedFunction",
    validator: validate_DeleteUserDefinedFunction_602582, base: "/",
    url: url_DeleteUserDefinedFunction_602583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWorkflow_602596 = ref object of OpenApiRestCall_601389
proc url_DeleteWorkflow_602598(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteWorkflow_602597(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a workflow.
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
  var valid_602599 = header.getOrDefault("X-Amz-Target")
  valid_602599 = validateParameter(valid_602599, JString, required = true,
                                 default = newJString("AWSGlue.DeleteWorkflow"))
  if valid_602599 != nil:
    section.add "X-Amz-Target", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Signature")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Signature", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Content-Sha256", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Date")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Date", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Credential")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Credential", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Security-Token")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Security-Token", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Algorithm")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Algorithm", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-SignedHeaders", valid_602606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602608: Call_DeleteWorkflow_602596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a workflow.
  ## 
  let valid = call_602608.validator(path, query, header, formData, body)
  let scheme = call_602608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602608.url(scheme.get, call_602608.host, call_602608.base,
                         call_602608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602608, url, valid)

proc call*(call_602609: Call_DeleteWorkflow_602596; body: JsonNode): Recallable =
  ## deleteWorkflow
  ## Deletes a workflow.
  ##   body: JObject (required)
  var body_602610 = newJObject()
  if body != nil:
    body_602610 = body
  result = call_602609.call(nil, nil, nil, nil, body_602610)

var deleteWorkflow* = Call_DeleteWorkflow_602596(name: "deleteWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.DeleteWorkflow",
    validator: validate_DeleteWorkflow_602597, base: "/", url: url_DeleteWorkflow_602598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCatalogImportStatus_602611 = ref object of OpenApiRestCall_601389
proc url_GetCatalogImportStatus_602613(protocol: Scheme; host: string; base: string;
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

proc validate_GetCatalogImportStatus_602612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the status of a migration operation.
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
  var valid_602614 = header.getOrDefault("X-Amz-Target")
  valid_602614 = validateParameter(valid_602614, JString, required = true, default = newJString(
      "AWSGlue.GetCatalogImportStatus"))
  if valid_602614 != nil:
    section.add "X-Amz-Target", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Signature")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Signature", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Content-Sha256", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Date")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Date", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Credential")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Credential", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Security-Token")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Security-Token", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Algorithm")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Algorithm", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-SignedHeaders", valid_602621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602623: Call_GetCatalogImportStatus_602611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the status of a migration operation.
  ## 
  let valid = call_602623.validator(path, query, header, formData, body)
  let scheme = call_602623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602623.url(scheme.get, call_602623.host, call_602623.base,
                         call_602623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602623, url, valid)

proc call*(call_602624: Call_GetCatalogImportStatus_602611; body: JsonNode): Recallable =
  ## getCatalogImportStatus
  ## Retrieves the status of a migration operation.
  ##   body: JObject (required)
  var body_602625 = newJObject()
  if body != nil:
    body_602625 = body
  result = call_602624.call(nil, nil, nil, nil, body_602625)

var getCatalogImportStatus* = Call_GetCatalogImportStatus_602611(
    name: "getCatalogImportStatus", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCatalogImportStatus",
    validator: validate_GetCatalogImportStatus_602612, base: "/",
    url: url_GetCatalogImportStatus_602613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifier_602626 = ref object of OpenApiRestCall_601389
proc url_GetClassifier_602628(protocol: Scheme; host: string; base: string;
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

proc validate_GetClassifier_602627(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a classifier by name.
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
  var valid_602629 = header.getOrDefault("X-Amz-Target")
  valid_602629 = validateParameter(valid_602629, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifier"))
  if valid_602629 != nil:
    section.add "X-Amz-Target", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Signature")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Signature", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Content-Sha256", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Date")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Date", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Credential")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Credential", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Security-Token")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Security-Token", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Algorithm")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Algorithm", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-SignedHeaders", valid_602636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602638: Call_GetClassifier_602626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a classifier by name.
  ## 
  let valid = call_602638.validator(path, query, header, formData, body)
  let scheme = call_602638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602638.url(scheme.get, call_602638.host, call_602638.base,
                         call_602638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602638, url, valid)

proc call*(call_602639: Call_GetClassifier_602626; body: JsonNode): Recallable =
  ## getClassifier
  ## Retrieve a classifier by name.
  ##   body: JObject (required)
  var body_602640 = newJObject()
  if body != nil:
    body_602640 = body
  result = call_602639.call(nil, nil, nil, nil, body_602640)

var getClassifier* = Call_GetClassifier_602626(name: "getClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifier",
    validator: validate_GetClassifier_602627, base: "/", url: url_GetClassifier_602628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetClassifiers_602641 = ref object of OpenApiRestCall_601389
proc url_GetClassifiers_602643(protocol: Scheme; host: string; base: string;
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

proc validate_GetClassifiers_602642(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602644 = query.getOrDefault("MaxResults")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "MaxResults", valid_602644
  var valid_602645 = query.getOrDefault("NextToken")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "NextToken", valid_602645
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
  var valid_602646 = header.getOrDefault("X-Amz-Target")
  valid_602646 = validateParameter(valid_602646, JString, required = true,
                                 default = newJString("AWSGlue.GetClassifiers"))
  if valid_602646 != nil:
    section.add "X-Amz-Target", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Signature")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Signature", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Content-Sha256", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Date")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Date", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Credential")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Credential", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Security-Token")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Security-Token", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Algorithm")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Algorithm", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-SignedHeaders", valid_602653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602655: Call_GetClassifiers_602641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all classifier objects in the Data Catalog.
  ## 
  let valid = call_602655.validator(path, query, header, formData, body)
  let scheme = call_602655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602655.url(scheme.get, call_602655.host, call_602655.base,
                         call_602655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602655, url, valid)

proc call*(call_602656: Call_GetClassifiers_602641; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getClassifiers
  ## Lists all classifier objects in the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602657 = newJObject()
  var body_602658 = newJObject()
  add(query_602657, "MaxResults", newJString(MaxResults))
  add(query_602657, "NextToken", newJString(NextToken))
  if body != nil:
    body_602658 = body
  result = call_602656.call(nil, query_602657, nil, nil, body_602658)

var getClassifiers* = Call_GetClassifiers_602641(name: "getClassifiers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetClassifiers",
    validator: validate_GetClassifiers_602642, base: "/", url: url_GetClassifiers_602643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnection_602660 = ref object of OpenApiRestCall_601389
proc url_GetConnection_602662(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnection_602661(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a connection definition from the Data Catalog.
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
  valid_602663 = validateParameter(valid_602663, JString, required = true,
                                 default = newJString("AWSGlue.GetConnection"))
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

proc call*(call_602672: Call_GetConnection_602660; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a connection definition from the Data Catalog.
  ## 
  let valid = call_602672.validator(path, query, header, formData, body)
  let scheme = call_602672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602672.url(scheme.get, call_602672.host, call_602672.base,
                         call_602672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602672, url, valid)

proc call*(call_602673: Call_GetConnection_602660; body: JsonNode): Recallable =
  ## getConnection
  ## Retrieves a connection definition from the Data Catalog.
  ##   body: JObject (required)
  var body_602674 = newJObject()
  if body != nil:
    body_602674 = body
  result = call_602673.call(nil, nil, nil, nil, body_602674)

var getConnection* = Call_GetConnection_602660(name: "getConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnection",
    validator: validate_GetConnection_602661, base: "/", url: url_GetConnection_602662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnections_602675 = ref object of OpenApiRestCall_601389
proc url_GetConnections_602677(protocol: Scheme; host: string; base: string;
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

proc validate_GetConnections_602676(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602678 = query.getOrDefault("MaxResults")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "MaxResults", valid_602678
  var valid_602679 = query.getOrDefault("NextToken")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "NextToken", valid_602679
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
  var valid_602680 = header.getOrDefault("X-Amz-Target")
  valid_602680 = validateParameter(valid_602680, JString, required = true,
                                 default = newJString("AWSGlue.GetConnections"))
  if valid_602680 != nil:
    section.add "X-Amz-Target", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Signature")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Signature", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Content-Sha256", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Date")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Date", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Credential")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Credential", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Algorithm")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Algorithm", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-SignedHeaders", valid_602687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602689: Call_GetConnections_602675; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of connection definitions from the Data Catalog.
  ## 
  let valid = call_602689.validator(path, query, header, formData, body)
  let scheme = call_602689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602689.url(scheme.get, call_602689.host, call_602689.base,
                         call_602689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602689, url, valid)

proc call*(call_602690: Call_GetConnections_602675; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getConnections
  ## Retrieves a list of connection definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602691 = newJObject()
  var body_602692 = newJObject()
  add(query_602691, "MaxResults", newJString(MaxResults))
  add(query_602691, "NextToken", newJString(NextToken))
  if body != nil:
    body_602692 = body
  result = call_602690.call(nil, query_602691, nil, nil, body_602692)

var getConnections* = Call_GetConnections_602675(name: "getConnections",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetConnections",
    validator: validate_GetConnections_602676, base: "/", url: url_GetConnections_602677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawler_602693 = ref object of OpenApiRestCall_601389
proc url_GetCrawler_602695(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetCrawler_602694(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for a specified crawler.
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
  var valid_602696 = header.getOrDefault("X-Amz-Target")
  valid_602696 = validateParameter(valid_602696, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawler"))
  if valid_602696 != nil:
    section.add "X-Amz-Target", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Signature")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Signature", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Content-Sha256", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Date")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Date", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Credential")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Credential", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-Security-Token")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-Security-Token", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Algorithm")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Algorithm", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-SignedHeaders", valid_602703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602705: Call_GetCrawler_602693; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for a specified crawler.
  ## 
  let valid = call_602705.validator(path, query, header, formData, body)
  let scheme = call_602705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602705.url(scheme.get, call_602705.host, call_602705.base,
                         call_602705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602705, url, valid)

proc call*(call_602706: Call_GetCrawler_602693; body: JsonNode): Recallable =
  ## getCrawler
  ## Retrieves metadata for a specified crawler.
  ##   body: JObject (required)
  var body_602707 = newJObject()
  if body != nil:
    body_602707 = body
  result = call_602706.call(nil, nil, nil, nil, body_602707)

var getCrawler* = Call_GetCrawler_602693(name: "getCrawler",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawler",
                                      validator: validate_GetCrawler_602694,
                                      base: "/", url: url_GetCrawler_602695,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlerMetrics_602708 = ref object of OpenApiRestCall_601389
proc url_GetCrawlerMetrics_602710(protocol: Scheme; host: string; base: string;
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

proc validate_GetCrawlerMetrics_602709(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves metrics about specified crawlers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602711 = query.getOrDefault("MaxResults")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "MaxResults", valid_602711
  var valid_602712 = query.getOrDefault("NextToken")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "NextToken", valid_602712
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
  var valid_602713 = header.getOrDefault("X-Amz-Target")
  valid_602713 = validateParameter(valid_602713, JString, required = true, default = newJString(
      "AWSGlue.GetCrawlerMetrics"))
  if valid_602713 != nil:
    section.add "X-Amz-Target", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Signature")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Signature", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Content-Sha256", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Date")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Date", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Credential")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Credential", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-Security-Token")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-Security-Token", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Algorithm")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Algorithm", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-SignedHeaders", valid_602720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602722: Call_GetCrawlerMetrics_602708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metrics about specified crawlers.
  ## 
  let valid = call_602722.validator(path, query, header, formData, body)
  let scheme = call_602722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602722.url(scheme.get, call_602722.host, call_602722.base,
                         call_602722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602722, url, valid)

proc call*(call_602723: Call_GetCrawlerMetrics_602708; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlerMetrics
  ## Retrieves metrics about specified crawlers.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602724 = newJObject()
  var body_602725 = newJObject()
  add(query_602724, "MaxResults", newJString(MaxResults))
  add(query_602724, "NextToken", newJString(NextToken))
  if body != nil:
    body_602725 = body
  result = call_602723.call(nil, query_602724, nil, nil, body_602725)

var getCrawlerMetrics* = Call_GetCrawlerMetrics_602708(name: "getCrawlerMetrics",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetCrawlerMetrics",
    validator: validate_GetCrawlerMetrics_602709, base: "/",
    url: url_GetCrawlerMetrics_602710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCrawlers_602726 = ref object of OpenApiRestCall_601389
proc url_GetCrawlers_602728(protocol: Scheme; host: string; base: string;
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

proc validate_GetCrawlers_602727(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602729 = query.getOrDefault("MaxResults")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "MaxResults", valid_602729
  var valid_602730 = query.getOrDefault("NextToken")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "NextToken", valid_602730
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
  var valid_602731 = header.getOrDefault("X-Amz-Target")
  valid_602731 = validateParameter(valid_602731, JString, required = true,
                                 default = newJString("AWSGlue.GetCrawlers"))
  if valid_602731 != nil:
    section.add "X-Amz-Target", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Signature")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Signature", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Content-Sha256", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Date")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Date", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Credential")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Credential", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Security-Token")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Security-Token", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Algorithm")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Algorithm", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-SignedHeaders", valid_602738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602740: Call_GetCrawlers_602726; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all crawlers defined in the customer account.
  ## 
  let valid = call_602740.validator(path, query, header, formData, body)
  let scheme = call_602740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602740.url(scheme.get, call_602740.host, call_602740.base,
                         call_602740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602740, url, valid)

proc call*(call_602741: Call_GetCrawlers_602726; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getCrawlers
  ## Retrieves metadata for all crawlers defined in the customer account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602742 = newJObject()
  var body_602743 = newJObject()
  add(query_602742, "MaxResults", newJString(MaxResults))
  add(query_602742, "NextToken", newJString(NextToken))
  if body != nil:
    body_602743 = body
  result = call_602741.call(nil, query_602742, nil, nil, body_602743)

var getCrawlers* = Call_GetCrawlers_602726(name: "getCrawlers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetCrawlers",
                                        validator: validate_GetCrawlers_602727,
                                        base: "/", url: url_GetCrawlers_602728,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataCatalogEncryptionSettings_602744 = ref object of OpenApiRestCall_601389
proc url_GetDataCatalogEncryptionSettings_602746(protocol: Scheme; host: string;
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

proc validate_GetDataCatalogEncryptionSettings_602745(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the security configuration for a specified catalog.
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
  var valid_602747 = header.getOrDefault("X-Amz-Target")
  valid_602747 = validateParameter(valid_602747, JString, required = true, default = newJString(
      "AWSGlue.GetDataCatalogEncryptionSettings"))
  if valid_602747 != nil:
    section.add "X-Amz-Target", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Signature")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Signature", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Content-Sha256", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-Date")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Date", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Credential")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Credential", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Security-Token")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Security-Token", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Algorithm")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Algorithm", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-SignedHeaders", valid_602754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602756: Call_GetDataCatalogEncryptionSettings_602744;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the security configuration for a specified catalog.
  ## 
  let valid = call_602756.validator(path, query, header, formData, body)
  let scheme = call_602756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602756.url(scheme.get, call_602756.host, call_602756.base,
                         call_602756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602756, url, valid)

proc call*(call_602757: Call_GetDataCatalogEncryptionSettings_602744;
          body: JsonNode): Recallable =
  ## getDataCatalogEncryptionSettings
  ## Retrieves the security configuration for a specified catalog.
  ##   body: JObject (required)
  var body_602758 = newJObject()
  if body != nil:
    body_602758 = body
  result = call_602757.call(nil, nil, nil, nil, body_602758)

var getDataCatalogEncryptionSettings* = Call_GetDataCatalogEncryptionSettings_602744(
    name: "getDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataCatalogEncryptionSettings",
    validator: validate_GetDataCatalogEncryptionSettings_602745, base: "/",
    url: url_GetDataCatalogEncryptionSettings_602746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabase_602759 = ref object of OpenApiRestCall_601389
proc url_GetDatabase_602761(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatabase_602760(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a specified database.
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
  var valid_602762 = header.getOrDefault("X-Amz-Target")
  valid_602762 = validateParameter(valid_602762, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabase"))
  if valid_602762 != nil:
    section.add "X-Amz-Target", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Signature")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Signature", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Content-Sha256", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-Date")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Date", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-Credential")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-Credential", valid_602766
  var valid_602767 = header.getOrDefault("X-Amz-Security-Token")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Security-Token", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-Algorithm")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Algorithm", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-SignedHeaders", valid_602769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602771: Call_GetDatabase_602759; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a specified database.
  ## 
  let valid = call_602771.validator(path, query, header, formData, body)
  let scheme = call_602771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602771.url(scheme.get, call_602771.host, call_602771.base,
                         call_602771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602771, url, valid)

proc call*(call_602772: Call_GetDatabase_602759; body: JsonNode): Recallable =
  ## getDatabase
  ## Retrieves the definition of a specified database.
  ##   body: JObject (required)
  var body_602773 = newJObject()
  if body != nil:
    body_602773 = body
  result = call_602772.call(nil, nil, nil, nil, body_602773)

var getDatabase* = Call_GetDatabase_602759(name: "getDatabase",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetDatabase",
                                        validator: validate_GetDatabase_602760,
                                        base: "/", url: url_GetDatabase_602761,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDatabases_602774 = ref object of OpenApiRestCall_601389
proc url_GetDatabases_602776(protocol: Scheme; host: string; base: string;
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

proc validate_GetDatabases_602775(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602777 = query.getOrDefault("MaxResults")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "MaxResults", valid_602777
  var valid_602778 = query.getOrDefault("NextToken")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "NextToken", valid_602778
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
  var valid_602779 = header.getOrDefault("X-Amz-Target")
  valid_602779 = validateParameter(valid_602779, JString, required = true,
                                 default = newJString("AWSGlue.GetDatabases"))
  if valid_602779 != nil:
    section.add "X-Amz-Target", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-Signature")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Signature", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Content-Sha256", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Date")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Date", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Credential")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Credential", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Security-Token")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Security-Token", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Algorithm")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Algorithm", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-SignedHeaders", valid_602786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602788: Call_GetDatabases_602774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all databases defined in a given Data Catalog.
  ## 
  let valid = call_602788.validator(path, query, header, formData, body)
  let scheme = call_602788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602788.url(scheme.get, call_602788.host, call_602788.base,
                         call_602788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602788, url, valid)

proc call*(call_602789: Call_GetDatabases_602774; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDatabases
  ## Retrieves all databases defined in a given Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602790 = newJObject()
  var body_602791 = newJObject()
  add(query_602790, "MaxResults", newJString(MaxResults))
  add(query_602790, "NextToken", newJString(NextToken))
  if body != nil:
    body_602791 = body
  result = call_602789.call(nil, query_602790, nil, nil, body_602791)

var getDatabases* = Call_GetDatabases_602774(name: "getDatabases",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDatabases",
    validator: validate_GetDatabases_602775, base: "/", url: url_GetDatabases_602776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowGraph_602792 = ref object of OpenApiRestCall_601389
proc url_GetDataflowGraph_602794(protocol: Scheme; host: string; base: string;
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

proc validate_GetDataflowGraph_602793(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
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
  var valid_602795 = header.getOrDefault("X-Amz-Target")
  valid_602795 = validateParameter(valid_602795, JString, required = true, default = newJString(
      "AWSGlue.GetDataflowGraph"))
  if valid_602795 != nil:
    section.add "X-Amz-Target", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Signature")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Signature", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Content-Sha256", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Date")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Date", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Credential")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Credential", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Security-Token")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Security-Token", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Algorithm")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Algorithm", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-SignedHeaders", valid_602802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602804: Call_GetDataflowGraph_602792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ## 
  let valid = call_602804.validator(path, query, header, formData, body)
  let scheme = call_602804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602804.url(scheme.get, call_602804.host, call_602804.base,
                         call_602804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602804, url, valid)

proc call*(call_602805: Call_GetDataflowGraph_602792; body: JsonNode): Recallable =
  ## getDataflowGraph
  ## Transforms a Python script into a directed acyclic graph (DAG). 
  ##   body: JObject (required)
  var body_602806 = newJObject()
  if body != nil:
    body_602806 = body
  result = call_602805.call(nil, nil, nil, nil, body_602806)

var getDataflowGraph* = Call_GetDataflowGraph_602792(name: "getDataflowGraph",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDataflowGraph",
    validator: validate_GetDataflowGraph_602793, base: "/",
    url: url_GetDataflowGraph_602794, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoint_602807 = ref object of OpenApiRestCall_601389
proc url_GetDevEndpoint_602809(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevEndpoint_602808(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
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
  var valid_602810 = header.getOrDefault("X-Amz-Target")
  valid_602810 = validateParameter(valid_602810, JString, required = true,
                                 default = newJString("AWSGlue.GetDevEndpoint"))
  if valid_602810 != nil:
    section.add "X-Amz-Target", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Signature")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Signature", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Content-Sha256", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-Date")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-Date", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Credential")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Credential", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Security-Token")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Security-Token", valid_602815
  var valid_602816 = header.getOrDefault("X-Amz-Algorithm")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-Algorithm", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-SignedHeaders", valid_602817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602819: Call_GetDevEndpoint_602807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_602819.validator(path, query, header, formData, body)
  let scheme = call_602819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602819.url(scheme.get, call_602819.host, call_602819.base,
                         call_602819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602819, url, valid)

proc call*(call_602820: Call_GetDevEndpoint_602807; body: JsonNode): Recallable =
  ## getDevEndpoint
  ## <p>Retrieves information about a specified development endpoint.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address, and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   body: JObject (required)
  var body_602821 = newJObject()
  if body != nil:
    body_602821 = body
  result = call_602820.call(nil, nil, nil, nil, body_602821)

var getDevEndpoint* = Call_GetDevEndpoint_602807(name: "getDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoint",
    validator: validate_GetDevEndpoint_602808, base: "/", url: url_GetDevEndpoint_602809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDevEndpoints_602822 = ref object of OpenApiRestCall_601389
proc url_GetDevEndpoints_602824(protocol: Scheme; host: string; base: string;
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

proc validate_GetDevEndpoints_602823(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602825 = query.getOrDefault("MaxResults")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "MaxResults", valid_602825
  var valid_602826 = query.getOrDefault("NextToken")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "NextToken", valid_602826
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
  var valid_602827 = header.getOrDefault("X-Amz-Target")
  valid_602827 = validateParameter(valid_602827, JString, required = true, default = newJString(
      "AWSGlue.GetDevEndpoints"))
  if valid_602827 != nil:
    section.add "X-Amz-Target", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-Signature")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Signature", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Content-Sha256", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Date")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Date", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Credential")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Credential", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Security-Token")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Security-Token", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Algorithm")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Algorithm", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-SignedHeaders", valid_602834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602836: Call_GetDevEndpoints_602822; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ## 
  let valid = call_602836.validator(path, query, header, formData, body)
  let scheme = call_602836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602836.url(scheme.get, call_602836.host, call_602836.base,
                         call_602836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602836, url, valid)

proc call*(call_602837: Call_GetDevEndpoints_602822; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDevEndpoints
  ## <p>Retrieves all the development endpoints in this AWS account.</p> <note> <p>When you create a development endpoint in a virtual private cloud (VPC), AWS Glue returns only a private IP address and the public IP address field is not populated. When you create a non-VPC development endpoint, AWS Glue returns only a public IP address.</p> </note>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602838 = newJObject()
  var body_602839 = newJObject()
  add(query_602838, "MaxResults", newJString(MaxResults))
  add(query_602838, "NextToken", newJString(NextToken))
  if body != nil:
    body_602839 = body
  result = call_602837.call(nil, query_602838, nil, nil, body_602839)

var getDevEndpoints* = Call_GetDevEndpoints_602822(name: "getDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetDevEndpoints",
    validator: validate_GetDevEndpoints_602823, base: "/", url: url_GetDevEndpoints_602824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJob_602840 = ref object of OpenApiRestCall_601389
proc url_GetJob_602842(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJob_602841(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves an existing job definition.
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
  var valid_602843 = header.getOrDefault("X-Amz-Target")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = newJString("AWSGlue.GetJob"))
  if valid_602843 != nil:
    section.add "X-Amz-Target", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Signature")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Signature", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Content-Sha256", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Date")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Date", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Credential")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Credential", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Security-Token")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Security-Token", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Algorithm")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Algorithm", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-SignedHeaders", valid_602850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602852: Call_GetJob_602840; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an existing job definition.
  ## 
  let valid = call_602852.validator(path, query, header, formData, body)
  let scheme = call_602852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602852.url(scheme.get, call_602852.host, call_602852.base,
                         call_602852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602852, url, valid)

proc call*(call_602853: Call_GetJob_602840; body: JsonNode): Recallable =
  ## getJob
  ## Retrieves an existing job definition.
  ##   body: JObject (required)
  var body_602854 = newJObject()
  if body != nil:
    body_602854 = body
  result = call_602853.call(nil, nil, nil, nil, body_602854)

var getJob* = Call_GetJob_602840(name: "getJob", meth: HttpMethod.HttpPost,
                              host: "glue.amazonaws.com",
                              route: "/#X-Amz-Target=AWSGlue.GetJob",
                              validator: validate_GetJob_602841, base: "/",
                              url: url_GetJob_602842,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobBookmark_602855 = ref object of OpenApiRestCall_601389
proc url_GetJobBookmark_602857(protocol: Scheme; host: string; base: string;
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

proc validate_GetJobBookmark_602856(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information on a job bookmark entry.
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
  var valid_602858 = header.getOrDefault("X-Amz-Target")
  valid_602858 = validateParameter(valid_602858, JString, required = true,
                                 default = newJString("AWSGlue.GetJobBookmark"))
  if valid_602858 != nil:
    section.add "X-Amz-Target", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Signature")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Signature", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Content-Sha256", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Date")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Date", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Credential")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Credential", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Security-Token")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Security-Token", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Algorithm")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Algorithm", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-SignedHeaders", valid_602865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602867: Call_GetJobBookmark_602855; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information on a job bookmark entry.
  ## 
  let valid = call_602867.validator(path, query, header, formData, body)
  let scheme = call_602867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602867.url(scheme.get, call_602867.host, call_602867.base,
                         call_602867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602867, url, valid)

proc call*(call_602868: Call_GetJobBookmark_602855; body: JsonNode): Recallable =
  ## getJobBookmark
  ## Returns information on a job bookmark entry.
  ##   body: JObject (required)
  var body_602869 = newJObject()
  if body != nil:
    body_602869 = body
  result = call_602868.call(nil, nil, nil, nil, body_602869)

var getJobBookmark* = Call_GetJobBookmark_602855(name: "getJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetJobBookmark",
    validator: validate_GetJobBookmark_602856, base: "/", url: url_GetJobBookmark_602857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRun_602870 = ref object of OpenApiRestCall_601389
proc url_GetJobRun_602872(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobRun_602871(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given job run.
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
  var valid_602873 = header.getOrDefault("X-Amz-Target")
  valid_602873 = validateParameter(valid_602873, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRun"))
  if valid_602873 != nil:
    section.add "X-Amz-Target", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Signature")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Signature", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Content-Sha256", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Date")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Date", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Credential")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Credential", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Security-Token")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Security-Token", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Algorithm")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Algorithm", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-SignedHeaders", valid_602880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_GetJobRun_602870; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given job run.
  ## 
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602882, url, valid)

proc call*(call_602883: Call_GetJobRun_602870; body: JsonNode): Recallable =
  ## getJobRun
  ## Retrieves the metadata for a given job run.
  ##   body: JObject (required)
  var body_602884 = newJObject()
  if body != nil:
    body_602884 = body
  result = call_602883.call(nil, nil, nil, nil, body_602884)

var getJobRun* = Call_GetJobRun_602870(name: "getJobRun", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetJobRun",
                                    validator: validate_GetJobRun_602871,
                                    base: "/", url: url_GetJobRun_602872,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobRuns_602885 = ref object of OpenApiRestCall_601389
proc url_GetJobRuns_602887(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobRuns_602886(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602888 = query.getOrDefault("MaxResults")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "MaxResults", valid_602888
  var valid_602889 = query.getOrDefault("NextToken")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "NextToken", valid_602889
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
  var valid_602890 = header.getOrDefault("X-Amz-Target")
  valid_602890 = validateParameter(valid_602890, JString, required = true,
                                 default = newJString("AWSGlue.GetJobRuns"))
  if valid_602890 != nil:
    section.add "X-Amz-Target", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Signature")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Signature", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Content-Sha256", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Date")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Date", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Credential")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Credential", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Security-Token")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Security-Token", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Algorithm")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Algorithm", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-SignedHeaders", valid_602897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602899: Call_GetJobRuns_602885; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given job definition.
  ## 
  let valid = call_602899.validator(path, query, header, formData, body)
  let scheme = call_602899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602899.url(scheme.get, call_602899.host, call_602899.base,
                         call_602899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602899, url, valid)

proc call*(call_602900: Call_GetJobRuns_602885; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getJobRuns
  ## Retrieves metadata for all runs of a given job definition.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602901 = newJObject()
  var body_602902 = newJObject()
  add(query_602901, "MaxResults", newJString(MaxResults))
  add(query_602901, "NextToken", newJString(NextToken))
  if body != nil:
    body_602902 = body
  result = call_602900.call(nil, query_602901, nil, nil, body_602902)

var getJobRuns* = Call_GetJobRuns_602885(name: "getJobRuns",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetJobRuns",
                                      validator: validate_GetJobRuns_602886,
                                      base: "/", url: url_GetJobRuns_602887,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobs_602903 = ref object of OpenApiRestCall_601389
proc url_GetJobs_602905(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetJobs_602904(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all current job definitions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602906 = query.getOrDefault("MaxResults")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "MaxResults", valid_602906
  var valid_602907 = query.getOrDefault("NextToken")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "NextToken", valid_602907
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
  var valid_602908 = header.getOrDefault("X-Amz-Target")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = newJString("AWSGlue.GetJobs"))
  if valid_602908 != nil:
    section.add "X-Amz-Target", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Signature")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Signature", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Content-Sha256", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Date")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Date", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Credential")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Credential", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Security-Token")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Security-Token", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Algorithm")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Algorithm", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-SignedHeaders", valid_602915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_GetJobs_602903; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all current job definitions.
  ## 
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602917, url, valid)

proc call*(call_602918: Call_GetJobs_602903; body: JsonNode; MaxResults: string = "";
          NextToken: string = ""): Recallable =
  ## getJobs
  ## Retrieves all current job definitions.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602919 = newJObject()
  var body_602920 = newJObject()
  add(query_602919, "MaxResults", newJString(MaxResults))
  add(query_602919, "NextToken", newJString(NextToken))
  if body != nil:
    body_602920 = body
  result = call_602918.call(nil, query_602919, nil, nil, body_602920)

var getJobs* = Call_GetJobs_602903(name: "getJobs", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetJobs",
                                validator: validate_GetJobs_602904, base: "/",
                                url: url_GetJobs_602905,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRun_602921 = ref object of OpenApiRestCall_601389
proc url_GetMLTaskRun_602923(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTaskRun_602922(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
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
  var valid_602924 = header.getOrDefault("X-Amz-Target")
  valid_602924 = validateParameter(valid_602924, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRun"))
  if valid_602924 != nil:
    section.add "X-Amz-Target", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Signature")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Signature", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Content-Sha256", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Date")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Date", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Credential")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Credential", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Security-Token")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Security-Token", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Algorithm")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Algorithm", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-SignedHeaders", valid_602931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602933: Call_GetMLTaskRun_602921; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ## 
  let valid = call_602933.validator(path, query, header, formData, body)
  let scheme = call_602933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602933.url(scheme.get, call_602933.host, call_602933.base,
                         call_602933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602933, url, valid)

proc call*(call_602934: Call_GetMLTaskRun_602921; body: JsonNode): Recallable =
  ## getMLTaskRun
  ## Gets details for a specific task run on a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can check the stats of any task run by calling <code>GetMLTaskRun</code> with the <code>TaskRunID</code> and its parent transform's <code>TransformID</code>.
  ##   body: JObject (required)
  var body_602935 = newJObject()
  if body != nil:
    body_602935 = body
  result = call_602934.call(nil, nil, nil, nil, body_602935)

var getMLTaskRun* = Call_GetMLTaskRun_602921(name: "getMLTaskRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRun",
    validator: validate_GetMLTaskRun_602922, base: "/", url: url_GetMLTaskRun_602923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTaskRuns_602936 = ref object of OpenApiRestCall_601389
proc url_GetMLTaskRuns_602938(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTaskRuns_602937(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602939 = query.getOrDefault("MaxResults")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "MaxResults", valid_602939
  var valid_602940 = query.getOrDefault("NextToken")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "NextToken", valid_602940
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
  var valid_602941 = header.getOrDefault("X-Amz-Target")
  valid_602941 = validateParameter(valid_602941, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTaskRuns"))
  if valid_602941 != nil:
    section.add "X-Amz-Target", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Signature")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Signature", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-Content-Sha256", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-Date")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-Date", valid_602944
  var valid_602945 = header.getOrDefault("X-Amz-Credential")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "X-Amz-Credential", valid_602945
  var valid_602946 = header.getOrDefault("X-Amz-Security-Token")
  valid_602946 = validateParameter(valid_602946, JString, required = false,
                                 default = nil)
  if valid_602946 != nil:
    section.add "X-Amz-Security-Token", valid_602946
  var valid_602947 = header.getOrDefault("X-Amz-Algorithm")
  valid_602947 = validateParameter(valid_602947, JString, required = false,
                                 default = nil)
  if valid_602947 != nil:
    section.add "X-Amz-Algorithm", valid_602947
  var valid_602948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-SignedHeaders", valid_602948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602950: Call_GetMLTaskRuns_602936; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ## 
  let valid = call_602950.validator(path, query, header, formData, body)
  let scheme = call_602950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602950.url(scheme.get, call_602950.host, call_602950.base,
                         call_602950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602950, url, valid)

proc call*(call_602951: Call_GetMLTaskRuns_602936; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTaskRuns
  ## <p>Gets a list of runs for a machine learning transform. Machine learning task runs are asynchronous tasks that AWS Glue runs on your behalf as part of various machine learning workflows. You can get a sortable, filterable list of machine learning task runs by calling <code>GetMLTaskRuns</code> with their parent transform's <code>TransformID</code> and other optional parameters as documented in this section.</p> <p>This operation returns a list of historic runs and must be paginated.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602952 = newJObject()
  var body_602953 = newJObject()
  add(query_602952, "MaxResults", newJString(MaxResults))
  add(query_602952, "NextToken", newJString(NextToken))
  if body != nil:
    body_602953 = body
  result = call_602951.call(nil, query_602952, nil, nil, body_602953)

var getMLTaskRuns* = Call_GetMLTaskRuns_602936(name: "getMLTaskRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTaskRuns",
    validator: validate_GetMLTaskRuns_602937, base: "/", url: url_GetMLTaskRuns_602938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransform_602954 = ref object of OpenApiRestCall_601389
proc url_GetMLTransform_602956(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTransform_602955(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
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
  var valid_602957 = header.getOrDefault("X-Amz-Target")
  valid_602957 = validateParameter(valid_602957, JString, required = true,
                                 default = newJString("AWSGlue.GetMLTransform"))
  if valid_602957 != nil:
    section.add "X-Amz-Target", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Signature")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Signature", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Content-Sha256", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Date")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Date", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Credential")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Credential", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Security-Token")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Security-Token", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Algorithm")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Algorithm", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-SignedHeaders", valid_602964
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602966: Call_GetMLTransform_602954; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ## 
  let valid = call_602966.validator(path, query, header, formData, body)
  let scheme = call_602966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602966.url(scheme.get, call_602966.host, call_602966.base,
                         call_602966.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602966, url, valid)

proc call*(call_602967: Call_GetMLTransform_602954; body: JsonNode): Recallable =
  ## getMLTransform
  ## Gets an AWS Glue machine learning transform artifact and all its corresponding metadata. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue. You can retrieve their metadata by calling <code>GetMLTransform</code>.
  ##   body: JObject (required)
  var body_602968 = newJObject()
  if body != nil:
    body_602968 = body
  result = call_602967.call(nil, nil, nil, nil, body_602968)

var getMLTransform* = Call_GetMLTransform_602954(name: "getMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransform",
    validator: validate_GetMLTransform_602955, base: "/", url: url_GetMLTransform_602956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMLTransforms_602969 = ref object of OpenApiRestCall_601389
proc url_GetMLTransforms_602971(protocol: Scheme; host: string; base: string;
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

proc validate_GetMLTransforms_602970(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602972 = query.getOrDefault("MaxResults")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "MaxResults", valid_602972
  var valid_602973 = query.getOrDefault("NextToken")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "NextToken", valid_602973
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
  var valid_602974 = header.getOrDefault("X-Amz-Target")
  valid_602974 = validateParameter(valid_602974, JString, required = true, default = newJString(
      "AWSGlue.GetMLTransforms"))
  if valid_602974 != nil:
    section.add "X-Amz-Target", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Signature")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Signature", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Content-Sha256", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Date")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Date", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Credential")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Credential", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-Security-Token")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-Security-Token", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-Algorithm")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Algorithm", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-SignedHeaders", valid_602981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602983: Call_GetMLTransforms_602969; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ## 
  let valid = call_602983.validator(path, query, header, formData, body)
  let scheme = call_602983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602983.url(scheme.get, call_602983.host, call_602983.base,
                         call_602983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602983, url, valid)

proc call*(call_602984: Call_GetMLTransforms_602969; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getMLTransforms
  ## Gets a sortable, filterable list of existing AWS Glue machine learning transforms. Machine learning transforms are a special type of transform that use machine learning to learn the details of the transformation to be performed by learning from examples provided by humans. These transformations are then saved by AWS Glue, and you can retrieve their metadata by calling <code>GetMLTransforms</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602985 = newJObject()
  var body_602986 = newJObject()
  add(query_602985, "MaxResults", newJString(MaxResults))
  add(query_602985, "NextToken", newJString(NextToken))
  if body != nil:
    body_602986 = body
  result = call_602984.call(nil, query_602985, nil, nil, body_602986)

var getMLTransforms* = Call_GetMLTransforms_602969(name: "getMLTransforms",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetMLTransforms",
    validator: validate_GetMLTransforms_602970, base: "/", url: url_GetMLTransforms_602971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMapping_602987 = ref object of OpenApiRestCall_601389
proc url_GetMapping_602989(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMapping_602988(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates mappings.
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
  var valid_602990 = header.getOrDefault("X-Amz-Target")
  valid_602990 = validateParameter(valid_602990, JString, required = true,
                                 default = newJString("AWSGlue.GetMapping"))
  if valid_602990 != nil:
    section.add "X-Amz-Target", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Signature")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Signature", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Content-Sha256", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Date")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Date", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Credential")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Credential", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-Security-Token")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-Security-Token", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-Algorithm")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Algorithm", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-SignedHeaders", valid_602997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602999: Call_GetMapping_602987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates mappings.
  ## 
  let valid = call_602999.validator(path, query, header, formData, body)
  let scheme = call_602999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602999.url(scheme.get, call_602999.host, call_602999.base,
                         call_602999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602999, url, valid)

proc call*(call_603000: Call_GetMapping_602987; body: JsonNode): Recallable =
  ## getMapping
  ## Creates mappings.
  ##   body: JObject (required)
  var body_603001 = newJObject()
  if body != nil:
    body_603001 = body
  result = call_603000.call(nil, nil, nil, nil, body_603001)

var getMapping* = Call_GetMapping_602987(name: "getMapping",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetMapping",
                                      validator: validate_GetMapping_602988,
                                      base: "/", url: url_GetMapping_602989,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartition_603002 = ref object of OpenApiRestCall_601389
proc url_GetPartition_603004(protocol: Scheme; host: string; base: string;
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

proc validate_GetPartition_603003(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specified partition.
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
  var valid_603005 = header.getOrDefault("X-Amz-Target")
  valid_603005 = validateParameter(valid_603005, JString, required = true,
                                 default = newJString("AWSGlue.GetPartition"))
  if valid_603005 != nil:
    section.add "X-Amz-Target", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Signature")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Signature", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Content-Sha256", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-Date")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-Date", valid_603008
  var valid_603009 = header.getOrDefault("X-Amz-Credential")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "X-Amz-Credential", valid_603009
  var valid_603010 = header.getOrDefault("X-Amz-Security-Token")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-Security-Token", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-Algorithm")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-Algorithm", valid_603011
  var valid_603012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "X-Amz-SignedHeaders", valid_603012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603014: Call_GetPartition_603002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specified partition.
  ## 
  let valid = call_603014.validator(path, query, header, formData, body)
  let scheme = call_603014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603014.url(scheme.get, call_603014.host, call_603014.base,
                         call_603014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603014, url, valid)

proc call*(call_603015: Call_GetPartition_603002; body: JsonNode): Recallable =
  ## getPartition
  ## Retrieves information about a specified partition.
  ##   body: JObject (required)
  var body_603016 = newJObject()
  if body != nil:
    body_603016 = body
  result = call_603015.call(nil, nil, nil, nil, body_603016)

var getPartition* = Call_GetPartition_603002(name: "getPartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartition",
    validator: validate_GetPartition_603003, base: "/", url: url_GetPartition_603004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPartitions_603017 = ref object of OpenApiRestCall_601389
proc url_GetPartitions_603019(protocol: Scheme; host: string; base: string;
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

proc validate_GetPartitions_603018(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about the partitions in a table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603020 = query.getOrDefault("MaxResults")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "MaxResults", valid_603020
  var valid_603021 = query.getOrDefault("NextToken")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "NextToken", valid_603021
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
  var valid_603022 = header.getOrDefault("X-Amz-Target")
  valid_603022 = validateParameter(valid_603022, JString, required = true,
                                 default = newJString("AWSGlue.GetPartitions"))
  if valid_603022 != nil:
    section.add "X-Amz-Target", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Signature")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Signature", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Content-Sha256", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Date")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Date", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Credential")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Credential", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Security-Token")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Security-Token", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Algorithm")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Algorithm", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-SignedHeaders", valid_603029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603031: Call_GetPartitions_603017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about the partitions in a table.
  ## 
  let valid = call_603031.validator(path, query, header, formData, body)
  let scheme = call_603031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603031.url(scheme.get, call_603031.host, call_603031.base,
                         call_603031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603031, url, valid)

proc call*(call_603032: Call_GetPartitions_603017; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getPartitions
  ## Retrieves information about the partitions in a table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603033 = newJObject()
  var body_603034 = newJObject()
  add(query_603033, "MaxResults", newJString(MaxResults))
  add(query_603033, "NextToken", newJString(NextToken))
  if body != nil:
    body_603034 = body
  result = call_603032.call(nil, query_603033, nil, nil, body_603034)

var getPartitions* = Call_GetPartitions_603017(name: "getPartitions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetPartitions",
    validator: validate_GetPartitions_603018, base: "/", url: url_GetPartitions_603019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPlan_603035 = ref object of OpenApiRestCall_601389
proc url_GetPlan_603037(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPlan_603036(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets code to perform a specified mapping.
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
  var valid_603038 = header.getOrDefault("X-Amz-Target")
  valid_603038 = validateParameter(valid_603038, JString, required = true,
                                 default = newJString("AWSGlue.GetPlan"))
  if valid_603038 != nil:
    section.add "X-Amz-Target", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Signature")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Signature", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Content-Sha256", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Date")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Date", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Credential")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Credential", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Security-Token")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Security-Token", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Algorithm")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Algorithm", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-SignedHeaders", valid_603045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603047: Call_GetPlan_603035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets code to perform a specified mapping.
  ## 
  let valid = call_603047.validator(path, query, header, formData, body)
  let scheme = call_603047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603047.url(scheme.get, call_603047.host, call_603047.base,
                         call_603047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603047, url, valid)

proc call*(call_603048: Call_GetPlan_603035; body: JsonNode): Recallable =
  ## getPlan
  ## Gets code to perform a specified mapping.
  ##   body: JObject (required)
  var body_603049 = newJObject()
  if body != nil:
    body_603049 = body
  result = call_603048.call(nil, nil, nil, nil, body_603049)

var getPlan* = Call_GetPlan_603035(name: "getPlan", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetPlan",
                                validator: validate_GetPlan_603036, base: "/",
                                url: url_GetPlan_603037,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourcePolicy_603050 = ref object of OpenApiRestCall_601389
proc url_GetResourcePolicy_603052(protocol: Scheme; host: string; base: string;
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

proc validate_GetResourcePolicy_603051(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves a specified resource policy.
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
  var valid_603053 = header.getOrDefault("X-Amz-Target")
  valid_603053 = validateParameter(valid_603053, JString, required = true, default = newJString(
      "AWSGlue.GetResourcePolicy"))
  if valid_603053 != nil:
    section.add "X-Amz-Target", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Signature")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Signature", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Content-Sha256", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Date")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Date", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Credential")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Credential", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Security-Token")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Security-Token", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Algorithm")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Algorithm", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-SignedHeaders", valid_603060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603062: Call_GetResourcePolicy_603050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified resource policy.
  ## 
  let valid = call_603062.validator(path, query, header, formData, body)
  let scheme = call_603062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603062.url(scheme.get, call_603062.host, call_603062.base,
                         call_603062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603062, url, valid)

proc call*(call_603063: Call_GetResourcePolicy_603050; body: JsonNode): Recallable =
  ## getResourcePolicy
  ## Retrieves a specified resource policy.
  ##   body: JObject (required)
  var body_603064 = newJObject()
  if body != nil:
    body_603064 = body
  result = call_603063.call(nil, nil, nil, nil, body_603064)

var getResourcePolicy* = Call_GetResourcePolicy_603050(name: "getResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetResourcePolicy",
    validator: validate_GetResourcePolicy_603051, base: "/",
    url: url_GetResourcePolicy_603052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfiguration_603065 = ref object of OpenApiRestCall_601389
proc url_GetSecurityConfiguration_603067(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSecurityConfiguration_603066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified security configuration.
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
  var valid_603068 = header.getOrDefault("X-Amz-Target")
  valid_603068 = validateParameter(valid_603068, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfiguration"))
  if valid_603068 != nil:
    section.add "X-Amz-Target", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Signature")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Signature", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Content-Sha256", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Date")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Date", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Credential")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Credential", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Algorithm")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Algorithm", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-SignedHeaders", valid_603075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_GetSecurityConfiguration_603065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified security configuration.
  ## 
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603077, url, valid)

proc call*(call_603078: Call_GetSecurityConfiguration_603065; body: JsonNode): Recallable =
  ## getSecurityConfiguration
  ## Retrieves a specified security configuration.
  ##   body: JObject (required)
  var body_603079 = newJObject()
  if body != nil:
    body_603079 = body
  result = call_603078.call(nil, nil, nil, nil, body_603079)

var getSecurityConfiguration* = Call_GetSecurityConfiguration_603065(
    name: "getSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfiguration",
    validator: validate_GetSecurityConfiguration_603066, base: "/",
    url: url_GetSecurityConfiguration_603067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSecurityConfigurations_603080 = ref object of OpenApiRestCall_601389
proc url_GetSecurityConfigurations_603082(protocol: Scheme; host: string;
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

proc validate_GetSecurityConfigurations_603081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of all security configurations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603083 = query.getOrDefault("MaxResults")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "MaxResults", valid_603083
  var valid_603084 = query.getOrDefault("NextToken")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "NextToken", valid_603084
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
  var valid_603085 = header.getOrDefault("X-Amz-Target")
  valid_603085 = validateParameter(valid_603085, JString, required = true, default = newJString(
      "AWSGlue.GetSecurityConfigurations"))
  if valid_603085 != nil:
    section.add "X-Amz-Target", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Content-Sha256", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Date")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Date", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Credential")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Credential", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Security-Token")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Security-Token", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Algorithm")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Algorithm", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-SignedHeaders", valid_603092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_GetSecurityConfigurations_603080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of all security configurations.
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603094, url, valid)

proc call*(call_603095: Call_GetSecurityConfigurations_603080; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getSecurityConfigurations
  ## Retrieves a list of all security configurations.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603096 = newJObject()
  var body_603097 = newJObject()
  add(query_603096, "MaxResults", newJString(MaxResults))
  add(query_603096, "NextToken", newJString(NextToken))
  if body != nil:
    body_603097 = body
  result = call_603095.call(nil, query_603096, nil, nil, body_603097)

var getSecurityConfigurations* = Call_GetSecurityConfigurations_603080(
    name: "getSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetSecurityConfigurations",
    validator: validate_GetSecurityConfigurations_603081, base: "/",
    url: url_GetSecurityConfigurations_603082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTable_603098 = ref object of OpenApiRestCall_601389
proc url_GetTable_603100(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTable_603099(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
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
  var valid_603101 = header.getOrDefault("X-Amz-Target")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = newJString("AWSGlue.GetTable"))
  if valid_603101 != nil:
    section.add "X-Amz-Target", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Signature")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Signature", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Content-Sha256", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Date")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Date", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Algorithm")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Algorithm", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-SignedHeaders", valid_603108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_GetTable_603098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603110, url, valid)

proc call*(call_603111: Call_GetTable_603098; body: JsonNode): Recallable =
  ## getTable
  ## Retrieves the <code>Table</code> definition in a Data Catalog for a specified table.
  ##   body: JObject (required)
  var body_603112 = newJObject()
  if body != nil:
    body_603112 = body
  result = call_603111.call(nil, nil, nil, nil, body_603112)

var getTable* = Call_GetTable_603098(name: "getTable", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.GetTable",
                                  validator: validate_GetTable_603099, base: "/",
                                  url: url_GetTable_603100,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersion_603113 = ref object of OpenApiRestCall_601389
proc url_GetTableVersion_603115(protocol: Scheme; host: string; base: string;
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

proc validate_GetTableVersion_603114(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a specified version of a table.
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
  var valid_603116 = header.getOrDefault("X-Amz-Target")
  valid_603116 = validateParameter(valid_603116, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersion"))
  if valid_603116 != nil:
    section.add "X-Amz-Target", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Signature")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Signature", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Content-Sha256", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Date")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Date", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Credential")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Credential", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Algorithm")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Algorithm", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-SignedHeaders", valid_603123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603125: Call_GetTableVersion_603113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified version of a table.
  ## 
  let valid = call_603125.validator(path, query, header, formData, body)
  let scheme = call_603125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603125.url(scheme.get, call_603125.host, call_603125.base,
                         call_603125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603125, url, valid)

proc call*(call_603126: Call_GetTableVersion_603113; body: JsonNode): Recallable =
  ## getTableVersion
  ## Retrieves a specified version of a table.
  ##   body: JObject (required)
  var body_603127 = newJObject()
  if body != nil:
    body_603127 = body
  result = call_603126.call(nil, nil, nil, nil, body_603127)

var getTableVersion* = Call_GetTableVersion_603113(name: "getTableVersion",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersion",
    validator: validate_GetTableVersion_603114, base: "/", url: url_GetTableVersion_603115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTableVersions_603128 = ref object of OpenApiRestCall_601389
proc url_GetTableVersions_603130(protocol: Scheme; host: string; base: string;
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

proc validate_GetTableVersions_603129(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603131 = query.getOrDefault("MaxResults")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "MaxResults", valid_603131
  var valid_603132 = query.getOrDefault("NextToken")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "NextToken", valid_603132
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
  var valid_603133 = header.getOrDefault("X-Amz-Target")
  valid_603133 = validateParameter(valid_603133, JString, required = true, default = newJString(
      "AWSGlue.GetTableVersions"))
  if valid_603133 != nil:
    section.add "X-Amz-Target", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Signature")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Signature", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Content-Sha256", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Date")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Date", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Credential")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Credential", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-SignedHeaders", valid_603140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603142: Call_GetTableVersions_603128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of strings that identify available versions of a specified table.
  ## 
  let valid = call_603142.validator(path, query, header, formData, body)
  let scheme = call_603142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603142.url(scheme.get, call_603142.host, call_603142.base,
                         call_603142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603142, url, valid)

proc call*(call_603143: Call_GetTableVersions_603128; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTableVersions
  ## Retrieves a list of strings that identify available versions of a specified table.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603144 = newJObject()
  var body_603145 = newJObject()
  add(query_603144, "MaxResults", newJString(MaxResults))
  add(query_603144, "NextToken", newJString(NextToken))
  if body != nil:
    body_603145 = body
  result = call_603143.call(nil, query_603144, nil, nil, body_603145)

var getTableVersions* = Call_GetTableVersions_603128(name: "getTableVersions",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetTableVersions",
    validator: validate_GetTableVersions_603129, base: "/",
    url: url_GetTableVersions_603130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTables_603146 = ref object of OpenApiRestCall_601389
proc url_GetTables_603148(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTables_603147(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603149 = query.getOrDefault("MaxResults")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "MaxResults", valid_603149
  var valid_603150 = query.getOrDefault("NextToken")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "NextToken", valid_603150
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
  var valid_603151 = header.getOrDefault("X-Amz-Target")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = newJString("AWSGlue.GetTables"))
  if valid_603151 != nil:
    section.add "X-Amz-Target", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Signature")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Signature", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Security-Token")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Security-Token", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_GetTables_603146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603160, url, valid)

proc call*(call_603161: Call_GetTables_603146; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTables
  ## Retrieves the definitions of some or all of the tables in a given <code>Database</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603162 = newJObject()
  var body_603163 = newJObject()
  add(query_603162, "MaxResults", newJString(MaxResults))
  add(query_603162, "NextToken", newJString(NextToken))
  if body != nil:
    body_603163 = body
  result = call_603161.call(nil, query_603162, nil, nil, body_603163)

var getTables* = Call_GetTables_603146(name: "getTables", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.GetTables",
                                    validator: validate_GetTables_603147,
                                    base: "/", url: url_GetTables_603148,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTags_603164 = ref object of OpenApiRestCall_601389
proc url_GetTags_603166(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTags_603165(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of tags associated with a resource.
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
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = newJString("AWSGlue.GetTags"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603176: Call_GetTags_603164; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of tags associated with a resource.
  ## 
  let valid = call_603176.validator(path, query, header, formData, body)
  let scheme = call_603176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603176.url(scheme.get, call_603176.host, call_603176.base,
                         call_603176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603176, url, valid)

proc call*(call_603177: Call_GetTags_603164; body: JsonNode): Recallable =
  ## getTags
  ## Retrieves a list of tags associated with a resource.
  ##   body: JObject (required)
  var body_603178 = newJObject()
  if body != nil:
    body_603178 = body
  result = call_603177.call(nil, nil, nil, nil, body_603178)

var getTags* = Call_GetTags_603164(name: "getTags", meth: HttpMethod.HttpPost,
                                host: "glue.amazonaws.com",
                                route: "/#X-Amz-Target=AWSGlue.GetTags",
                                validator: validate_GetTags_603165, base: "/",
                                url: url_GetTags_603166,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrigger_603179 = ref object of OpenApiRestCall_601389
proc url_GetTrigger_603181(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTrigger_603180(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the definition of a trigger.
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
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = newJString("AWSGlue.GetTrigger"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Signature")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Signature", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603191: Call_GetTrigger_603179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the definition of a trigger.
  ## 
  let valid = call_603191.validator(path, query, header, formData, body)
  let scheme = call_603191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603191.url(scheme.get, call_603191.host, call_603191.base,
                         call_603191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603191, url, valid)

proc call*(call_603192: Call_GetTrigger_603179; body: JsonNode): Recallable =
  ## getTrigger
  ## Retrieves the definition of a trigger.
  ##   body: JObject (required)
  var body_603193 = newJObject()
  if body != nil:
    body_603193 = body
  result = call_603192.call(nil, nil, nil, nil, body_603193)

var getTrigger* = Call_GetTrigger_603179(name: "getTrigger",
                                      meth: HttpMethod.HttpPost,
                                      host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTrigger",
                                      validator: validate_GetTrigger_603180,
                                      base: "/", url: url_GetTrigger_603181,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTriggers_603194 = ref object of OpenApiRestCall_601389
proc url_GetTriggers_603196(protocol: Scheme; host: string; base: string;
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

proc validate_GetTriggers_603195(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets all the triggers associated with a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603197 = query.getOrDefault("MaxResults")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "MaxResults", valid_603197
  var valid_603198 = query.getOrDefault("NextToken")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "NextToken", valid_603198
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
  var valid_603199 = header.getOrDefault("X-Amz-Target")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = newJString("AWSGlue.GetTriggers"))
  if valid_603199 != nil:
    section.add "X-Amz-Target", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Content-Sha256", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Security-Token")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Security-Token", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Algorithm")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Algorithm", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-SignedHeaders", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_GetTriggers_603194; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets all the triggers associated with a job.
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603208, url, valid)

proc call*(call_603209: Call_GetTriggers_603194; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getTriggers
  ## Gets all the triggers associated with a job.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603210 = newJObject()
  var body_603211 = newJObject()
  add(query_603210, "MaxResults", newJString(MaxResults))
  add(query_603210, "NextToken", newJString(NextToken))
  if body != nil:
    body_603211 = body
  result = call_603209.call(nil, query_603210, nil, nil, body_603211)

var getTriggers* = Call_GetTriggers_603194(name: "getTriggers",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetTriggers",
                                        validator: validate_GetTriggers_603195,
                                        base: "/", url: url_GetTriggers_603196,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunction_603212 = ref object of OpenApiRestCall_601389
proc url_GetUserDefinedFunction_603214(protocol: Scheme; host: string; base: string;
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

proc validate_GetUserDefinedFunction_603213(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a specified function definition from the Data Catalog.
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
  var valid_603215 = header.getOrDefault("X-Amz-Target")
  valid_603215 = validateParameter(valid_603215, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunction"))
  if valid_603215 != nil:
    section.add "X-Amz-Target", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Signature")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Signature", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Date")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Date", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Credential")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Credential", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Security-Token")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Security-Token", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Algorithm")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Algorithm", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-SignedHeaders", valid_603222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_GetUserDefinedFunction_603212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a specified function definition from the Data Catalog.
  ## 
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603224, url, valid)

proc call*(call_603225: Call_GetUserDefinedFunction_603212; body: JsonNode): Recallable =
  ## getUserDefinedFunction
  ## Retrieves a specified function definition from the Data Catalog.
  ##   body: JObject (required)
  var body_603226 = newJObject()
  if body != nil:
    body_603226 = body
  result = call_603225.call(nil, nil, nil, nil, body_603226)

var getUserDefinedFunction* = Call_GetUserDefinedFunction_603212(
    name: "getUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunction",
    validator: validate_GetUserDefinedFunction_603213, base: "/",
    url: url_GetUserDefinedFunction_603214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUserDefinedFunctions_603227 = ref object of OpenApiRestCall_601389
proc url_GetUserDefinedFunctions_603229(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUserDefinedFunctions_603228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603230 = query.getOrDefault("MaxResults")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "MaxResults", valid_603230
  var valid_603231 = query.getOrDefault("NextToken")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "NextToken", valid_603231
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
  var valid_603232 = header.getOrDefault("X-Amz-Target")
  valid_603232 = validateParameter(valid_603232, JString, required = true, default = newJString(
      "AWSGlue.GetUserDefinedFunctions"))
  if valid_603232 != nil:
    section.add "X-Amz-Target", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Signature")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Signature", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Content-Sha256", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Security-Token")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Security-Token", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Algorithm")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Algorithm", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-SignedHeaders", valid_603239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603241: Call_GetUserDefinedFunctions_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves multiple function definitions from the Data Catalog.
  ## 
  let valid = call_603241.validator(path, query, header, formData, body)
  let scheme = call_603241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603241.url(scheme.get, call_603241.host, call_603241.base,
                         call_603241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603241, url, valid)

proc call*(call_603242: Call_GetUserDefinedFunctions_603227; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getUserDefinedFunctions
  ## Retrieves multiple function definitions from the Data Catalog.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603243 = newJObject()
  var body_603244 = newJObject()
  add(query_603243, "MaxResults", newJString(MaxResults))
  add(query_603243, "NextToken", newJString(NextToken))
  if body != nil:
    body_603244 = body
  result = call_603242.call(nil, query_603243, nil, nil, body_603244)

var getUserDefinedFunctions* = Call_GetUserDefinedFunctions_603227(
    name: "getUserDefinedFunctions", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetUserDefinedFunctions",
    validator: validate_GetUserDefinedFunctions_603228, base: "/",
    url: url_GetUserDefinedFunctions_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflow_603245 = ref object of OpenApiRestCall_601389
proc url_GetWorkflow_603247(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflow_603246(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves resource metadata for a workflow.
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
  var valid_603248 = header.getOrDefault("X-Amz-Target")
  valid_603248 = validateParameter(valid_603248, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflow"))
  if valid_603248 != nil:
    section.add "X-Amz-Target", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Signature")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Signature", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Content-Sha256", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Date")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Date", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Credential")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Credential", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Security-Token")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Security-Token", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Algorithm")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Algorithm", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-SignedHeaders", valid_603255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603257: Call_GetWorkflow_603245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves resource metadata for a workflow.
  ## 
  let valid = call_603257.validator(path, query, header, formData, body)
  let scheme = call_603257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603257.url(scheme.get, call_603257.host, call_603257.base,
                         call_603257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603257, url, valid)

proc call*(call_603258: Call_GetWorkflow_603245; body: JsonNode): Recallable =
  ## getWorkflow
  ## Retrieves resource metadata for a workflow.
  ##   body: JObject (required)
  var body_603259 = newJObject()
  if body != nil:
    body_603259 = body
  result = call_603258.call(nil, nil, nil, nil, body_603259)

var getWorkflow* = Call_GetWorkflow_603245(name: "getWorkflow",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.GetWorkflow",
                                        validator: validate_GetWorkflow_603246,
                                        base: "/", url: url_GetWorkflow_603247,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRun_603260 = ref object of OpenApiRestCall_601389
proc url_GetWorkflowRun_603262(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflowRun_603261(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves the metadata for a given workflow run. 
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
  var valid_603263 = header.getOrDefault("X-Amz-Target")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = newJString("AWSGlue.GetWorkflowRun"))
  if valid_603263 != nil:
    section.add "X-Amz-Target", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Signature")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Signature", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Content-Sha256", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Date")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Date", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Credential")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Credential", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Security-Token")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Security-Token", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Algorithm")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Algorithm", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-SignedHeaders", valid_603270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603272: Call_GetWorkflowRun_603260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the metadata for a given workflow run. 
  ## 
  let valid = call_603272.validator(path, query, header, formData, body)
  let scheme = call_603272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603272.url(scheme.get, call_603272.host, call_603272.base,
                         call_603272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603272, url, valid)

proc call*(call_603273: Call_GetWorkflowRun_603260; body: JsonNode): Recallable =
  ## getWorkflowRun
  ## Retrieves the metadata for a given workflow run. 
  ##   body: JObject (required)
  var body_603274 = newJObject()
  if body != nil:
    body_603274 = body
  result = call_603273.call(nil, nil, nil, nil, body_603274)

var getWorkflowRun* = Call_GetWorkflowRun_603260(name: "getWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRun",
    validator: validate_GetWorkflowRun_603261, base: "/", url: url_GetWorkflowRun_603262,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRunProperties_603275 = ref object of OpenApiRestCall_601389
proc url_GetWorkflowRunProperties_603277(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWorkflowRunProperties_603276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the workflow run properties which were set during the run.
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
  var valid_603278 = header.getOrDefault("X-Amz-Target")
  valid_603278 = validateParameter(valid_603278, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRunProperties"))
  if valid_603278 != nil:
    section.add "X-Amz-Target", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Content-Sha256", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Date")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Date", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Credential")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Credential", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Algorithm")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Algorithm", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-SignedHeaders", valid_603285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603287: Call_GetWorkflowRunProperties_603275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the workflow run properties which were set during the run.
  ## 
  let valid = call_603287.validator(path, query, header, formData, body)
  let scheme = call_603287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603287.url(scheme.get, call_603287.host, call_603287.base,
                         call_603287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603287, url, valid)

proc call*(call_603288: Call_GetWorkflowRunProperties_603275; body: JsonNode): Recallable =
  ## getWorkflowRunProperties
  ## Retrieves the workflow run properties which were set during the run.
  ##   body: JObject (required)
  var body_603289 = newJObject()
  if body != nil:
    body_603289 = body
  result = call_603288.call(nil, nil, nil, nil, body_603289)

var getWorkflowRunProperties* = Call_GetWorkflowRunProperties_603275(
    name: "getWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRunProperties",
    validator: validate_GetWorkflowRunProperties_603276, base: "/",
    url: url_GetWorkflowRunProperties_603277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWorkflowRuns_603290 = ref object of OpenApiRestCall_601389
proc url_GetWorkflowRuns_603292(protocol: Scheme; host: string; base: string;
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

proc validate_GetWorkflowRuns_603291(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603293 = query.getOrDefault("MaxResults")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "MaxResults", valid_603293
  var valid_603294 = query.getOrDefault("NextToken")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "NextToken", valid_603294
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
  var valid_603295 = header.getOrDefault("X-Amz-Target")
  valid_603295 = validateParameter(valid_603295, JString, required = true, default = newJString(
      "AWSGlue.GetWorkflowRuns"))
  if valid_603295 != nil:
    section.add "X-Amz-Target", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Signature")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Signature", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Content-Sha256", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Date")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Date", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Credential")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Credential", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Security-Token")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Security-Token", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Algorithm")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Algorithm", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-SignedHeaders", valid_603302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603304: Call_GetWorkflowRuns_603290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves metadata for all runs of a given workflow.
  ## 
  let valid = call_603304.validator(path, query, header, formData, body)
  let scheme = call_603304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603304.url(scheme.get, call_603304.host, call_603304.base,
                         call_603304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603304, url, valid)

proc call*(call_603305: Call_GetWorkflowRuns_603290; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getWorkflowRuns
  ## Retrieves metadata for all runs of a given workflow.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603306 = newJObject()
  var body_603307 = newJObject()
  add(query_603306, "MaxResults", newJString(MaxResults))
  add(query_603306, "NextToken", newJString(NextToken))
  if body != nil:
    body_603307 = body
  result = call_603305.call(nil, query_603306, nil, nil, body_603307)

var getWorkflowRuns* = Call_GetWorkflowRuns_603290(name: "getWorkflowRuns",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.GetWorkflowRuns",
    validator: validate_GetWorkflowRuns_603291, base: "/", url: url_GetWorkflowRuns_603292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportCatalogToGlue_603308 = ref object of OpenApiRestCall_601389
proc url_ImportCatalogToGlue_603310(protocol: Scheme; host: string; base: string;
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

proc validate_ImportCatalogToGlue_603309(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
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
  var valid_603311 = header.getOrDefault("X-Amz-Target")
  valid_603311 = validateParameter(valid_603311, JString, required = true, default = newJString(
      "AWSGlue.ImportCatalogToGlue"))
  if valid_603311 != nil:
    section.add "X-Amz-Target", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Signature")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Signature", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Content-Sha256", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Date")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Date", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Credential")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Credential", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Algorithm")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Algorithm", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-SignedHeaders", valid_603318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603320: Call_ImportCatalogToGlue_603308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ## 
  let valid = call_603320.validator(path, query, header, formData, body)
  let scheme = call_603320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603320.url(scheme.get, call_603320.host, call_603320.base,
                         call_603320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603320, url, valid)

proc call*(call_603321: Call_ImportCatalogToGlue_603308; body: JsonNode): Recallable =
  ## importCatalogToGlue
  ## Imports an existing Amazon Athena Data Catalog to AWS Glue
  ##   body: JObject (required)
  var body_603322 = newJObject()
  if body != nil:
    body_603322 = body
  result = call_603321.call(nil, nil, nil, nil, body_603322)

var importCatalogToGlue* = Call_ImportCatalogToGlue_603308(
    name: "importCatalogToGlue", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ImportCatalogToGlue",
    validator: validate_ImportCatalogToGlue_603309, base: "/",
    url: url_ImportCatalogToGlue_603310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCrawlers_603323 = ref object of OpenApiRestCall_601389
proc url_ListCrawlers_603325(protocol: Scheme; host: string; base: string;
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

proc validate_ListCrawlers_603324(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603326 = query.getOrDefault("MaxResults")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "MaxResults", valid_603326
  var valid_603327 = query.getOrDefault("NextToken")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "NextToken", valid_603327
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
  var valid_603328 = header.getOrDefault("X-Amz-Target")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = newJString("AWSGlue.ListCrawlers"))
  if valid_603328 != nil:
    section.add "X-Amz-Target", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Signature")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Signature", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Content-Sha256", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Date")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Date", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Credential")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Credential", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Security-Token")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Security-Token", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-SignedHeaders", valid_603335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603337: Call_ListCrawlers_603323; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_603337.validator(path, query, header, formData, body)
  let scheme = call_603337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603337.url(scheme.get, call_603337.host, call_603337.base,
                         call_603337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603337, url, valid)

proc call*(call_603338: Call_ListCrawlers_603323; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCrawlers
  ## <p>Retrieves the names of all crawler resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603339 = newJObject()
  var body_603340 = newJObject()
  add(query_603339, "MaxResults", newJString(MaxResults))
  add(query_603339, "NextToken", newJString(NextToken))
  if body != nil:
    body_603340 = body
  result = call_603338.call(nil, query_603339, nil, nil, body_603340)

var listCrawlers* = Call_ListCrawlers_603323(name: "listCrawlers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListCrawlers",
    validator: validate_ListCrawlers_603324, base: "/", url: url_ListCrawlers_603325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDevEndpoints_603341 = ref object of OpenApiRestCall_601389
proc url_ListDevEndpoints_603343(protocol: Scheme; host: string; base: string;
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

proc validate_ListDevEndpoints_603342(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603344 = query.getOrDefault("MaxResults")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "MaxResults", valid_603344
  var valid_603345 = query.getOrDefault("NextToken")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "NextToken", valid_603345
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
  var valid_603346 = header.getOrDefault("X-Amz-Target")
  valid_603346 = validateParameter(valid_603346, JString, required = true, default = newJString(
      "AWSGlue.ListDevEndpoints"))
  if valid_603346 != nil:
    section.add "X-Amz-Target", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Credential")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Credential", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Security-Token")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Security-Token", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Algorithm")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Algorithm", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-SignedHeaders", valid_603353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603355: Call_ListDevEndpoints_603341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_603355.validator(path, query, header, formData, body)
  let scheme = call_603355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603355.url(scheme.get, call_603355.host, call_603355.base,
                         call_603355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603355, url, valid)

proc call*(call_603356: Call_ListDevEndpoints_603341; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDevEndpoints
  ## <p>Retrieves the names of all <code>DevEndpoint</code> resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603357 = newJObject()
  var body_603358 = newJObject()
  add(query_603357, "MaxResults", newJString(MaxResults))
  add(query_603357, "NextToken", newJString(NextToken))
  if body != nil:
    body_603358 = body
  result = call_603356.call(nil, query_603357, nil, nil, body_603358)

var listDevEndpoints* = Call_ListDevEndpoints_603341(name: "listDevEndpoints",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListDevEndpoints",
    validator: validate_ListDevEndpoints_603342, base: "/",
    url: url_ListDevEndpoints_603343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_603359 = ref object of OpenApiRestCall_601389
proc url_ListJobs_603361(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_603360(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603362 = query.getOrDefault("MaxResults")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "MaxResults", valid_603362
  var valid_603363 = query.getOrDefault("NextToken")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "NextToken", valid_603363
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
  var valid_603364 = header.getOrDefault("X-Amz-Target")
  valid_603364 = validateParameter(valid_603364, JString, required = true,
                                 default = newJString("AWSGlue.ListJobs"))
  if valid_603364 != nil:
    section.add "X-Amz-Target", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Date")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Date", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Credential")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Credential", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-Security-Token")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-Security-Token", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Algorithm")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Algorithm", valid_603370
  var valid_603371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-SignedHeaders", valid_603371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_ListJobs_603359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603373, url, valid)

proc call*(call_603374: Call_ListJobs_603359; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Retrieves the names of all job resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603375 = newJObject()
  var body_603376 = newJObject()
  add(query_603375, "MaxResults", newJString(MaxResults))
  add(query_603375, "NextToken", newJString(NextToken))
  if body != nil:
    body_603376 = body
  result = call_603374.call(nil, query_603375, nil, nil, body_603376)

var listJobs* = Call_ListJobs_603359(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "glue.amazonaws.com",
                                  route: "/#X-Amz-Target=AWSGlue.ListJobs",
                                  validator: validate_ListJobs_603360, base: "/",
                                  url: url_ListJobs_603361,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTriggers_603377 = ref object of OpenApiRestCall_601389
proc url_ListTriggers_603379(protocol: Scheme; host: string; base: string;
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

proc validate_ListTriggers_603378(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603380 = query.getOrDefault("MaxResults")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "MaxResults", valid_603380
  var valid_603381 = query.getOrDefault("NextToken")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "NextToken", valid_603381
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
  var valid_603382 = header.getOrDefault("X-Amz-Target")
  valid_603382 = validateParameter(valid_603382, JString, required = true,
                                 default = newJString("AWSGlue.ListTriggers"))
  if valid_603382 != nil:
    section.add "X-Amz-Target", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Signature")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Signature", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Content-Sha256", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Date")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Date", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Credential")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Credential", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Security-Token")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Security-Token", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Algorithm")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Algorithm", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-SignedHeaders", valid_603389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603391: Call_ListTriggers_603377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ## 
  let valid = call_603391.validator(path, query, header, formData, body)
  let scheme = call_603391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603391.url(scheme.get, call_603391.host, call_603391.base,
                         call_603391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603391, url, valid)

proc call*(call_603392: Call_ListTriggers_603377; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTriggers
  ## <p>Retrieves the names of all trigger resources in this AWS account, or the resources with the specified tag. This operation allows you to see which resources are available in your account, and their names.</p> <p>This operation takes the optional <code>Tags</code> field, which you can use as a filter on the response so that tagged resources can be retrieved as a group. If you choose to use tags filtering, only resources with the tag are retrieved.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603393 = newJObject()
  var body_603394 = newJObject()
  add(query_603393, "MaxResults", newJString(MaxResults))
  add(query_603393, "NextToken", newJString(NextToken))
  if body != nil:
    body_603394 = body
  result = call_603392.call(nil, query_603393, nil, nil, body_603394)

var listTriggers* = Call_ListTriggers_603377(name: "listTriggers",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListTriggers",
    validator: validate_ListTriggers_603378, base: "/", url: url_ListTriggers_603379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWorkflows_603395 = ref object of OpenApiRestCall_601389
proc url_ListWorkflows_603397(protocol: Scheme; host: string; base: string;
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

proc validate_ListWorkflows_603396(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists names of workflows created in the account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603398 = query.getOrDefault("MaxResults")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "MaxResults", valid_603398
  var valid_603399 = query.getOrDefault("NextToken")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "NextToken", valid_603399
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
  var valid_603400 = header.getOrDefault("X-Amz-Target")
  valid_603400 = validateParameter(valid_603400, JString, required = true,
                                 default = newJString("AWSGlue.ListWorkflows"))
  if valid_603400 != nil:
    section.add "X-Amz-Target", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Signature")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Signature", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Content-Sha256", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Date")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Date", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Security-Token")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Security-Token", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Algorithm")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Algorithm", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-SignedHeaders", valid_603407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603409: Call_ListWorkflows_603395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists names of workflows created in the account.
  ## 
  let valid = call_603409.validator(path, query, header, formData, body)
  let scheme = call_603409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603409.url(scheme.get, call_603409.host, call_603409.base,
                         call_603409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603409, url, valid)

proc call*(call_603410: Call_ListWorkflows_603395; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listWorkflows
  ## Lists names of workflows created in the account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603411 = newJObject()
  var body_603412 = newJObject()
  add(query_603411, "MaxResults", newJString(MaxResults))
  add(query_603411, "NextToken", newJString(NextToken))
  if body != nil:
    body_603412 = body
  result = call_603410.call(nil, query_603411, nil, nil, body_603412)

var listWorkflows* = Call_ListWorkflows_603395(name: "listWorkflows",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ListWorkflows",
    validator: validate_ListWorkflows_603396, base: "/", url: url_ListWorkflows_603397,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDataCatalogEncryptionSettings_603413 = ref object of OpenApiRestCall_601389
proc url_PutDataCatalogEncryptionSettings_603415(protocol: Scheme; host: string;
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

proc validate_PutDataCatalogEncryptionSettings_603414(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
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
  var valid_603416 = header.getOrDefault("X-Amz-Target")
  valid_603416 = validateParameter(valid_603416, JString, required = true, default = newJString(
      "AWSGlue.PutDataCatalogEncryptionSettings"))
  if valid_603416 != nil:
    section.add "X-Amz-Target", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Signature")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Signature", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Content-Sha256", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Date")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Date", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Credential")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Credential", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Algorithm")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Algorithm", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-SignedHeaders", valid_603423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603425: Call_PutDataCatalogEncryptionSettings_603413;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ## 
  let valid = call_603425.validator(path, query, header, formData, body)
  let scheme = call_603425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603425.url(scheme.get, call_603425.host, call_603425.base,
                         call_603425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603425, url, valid)

proc call*(call_603426: Call_PutDataCatalogEncryptionSettings_603413;
          body: JsonNode): Recallable =
  ## putDataCatalogEncryptionSettings
  ## Sets the security configuration for a specified catalog. After the configuration has been set, the specified encryption is applied to every catalog write thereafter.
  ##   body: JObject (required)
  var body_603427 = newJObject()
  if body != nil:
    body_603427 = body
  result = call_603426.call(nil, nil, nil, nil, body_603427)

var putDataCatalogEncryptionSettings* = Call_PutDataCatalogEncryptionSettings_603413(
    name: "putDataCatalogEncryptionSettings", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutDataCatalogEncryptionSettings",
    validator: validate_PutDataCatalogEncryptionSettings_603414, base: "/",
    url: url_PutDataCatalogEncryptionSettings_603415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutResourcePolicy_603428 = ref object of OpenApiRestCall_601389
proc url_PutResourcePolicy_603430(protocol: Scheme; host: string; base: string;
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

proc validate_PutResourcePolicy_603429(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Sets the Data Catalog resource policy for access control.
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
  var valid_603431 = header.getOrDefault("X-Amz-Target")
  valid_603431 = validateParameter(valid_603431, JString, required = true, default = newJString(
      "AWSGlue.PutResourcePolicy"))
  if valid_603431 != nil:
    section.add "X-Amz-Target", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Signature")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Signature", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Content-Sha256", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Date")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Date", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Credential")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Credential", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Algorithm")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Algorithm", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-SignedHeaders", valid_603438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603440: Call_PutResourcePolicy_603428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the Data Catalog resource policy for access control.
  ## 
  let valid = call_603440.validator(path, query, header, formData, body)
  let scheme = call_603440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603440.url(scheme.get, call_603440.host, call_603440.base,
                         call_603440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603440, url, valid)

proc call*(call_603441: Call_PutResourcePolicy_603428; body: JsonNode): Recallable =
  ## putResourcePolicy
  ## Sets the Data Catalog resource policy for access control.
  ##   body: JObject (required)
  var body_603442 = newJObject()
  if body != nil:
    body_603442 = body
  result = call_603441.call(nil, nil, nil, nil, body_603442)

var putResourcePolicy* = Call_PutResourcePolicy_603428(name: "putResourcePolicy",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutResourcePolicy",
    validator: validate_PutResourcePolicy_603429, base: "/",
    url: url_PutResourcePolicy_603430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutWorkflowRunProperties_603443 = ref object of OpenApiRestCall_601389
proc url_PutWorkflowRunProperties_603445(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutWorkflowRunProperties_603444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
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
  var valid_603446 = header.getOrDefault("X-Amz-Target")
  valid_603446 = validateParameter(valid_603446, JString, required = true, default = newJString(
      "AWSGlue.PutWorkflowRunProperties"))
  if valid_603446 != nil:
    section.add "X-Amz-Target", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Signature")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Signature", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Content-Sha256", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Date")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Date", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Credential")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Credential", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Algorithm")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Algorithm", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-SignedHeaders", valid_603453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603455: Call_PutWorkflowRunProperties_603443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ## 
  let valid = call_603455.validator(path, query, header, formData, body)
  let scheme = call_603455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603455.url(scheme.get, call_603455.host, call_603455.base,
                         call_603455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603455, url, valid)

proc call*(call_603456: Call_PutWorkflowRunProperties_603443; body: JsonNode): Recallable =
  ## putWorkflowRunProperties
  ## Puts the specified workflow run properties for the given workflow run. If a property already exists for the specified run, then it overrides the value otherwise adds the property to existing properties.
  ##   body: JObject (required)
  var body_603457 = newJObject()
  if body != nil:
    body_603457 = body
  result = call_603456.call(nil, nil, nil, nil, body_603457)

var putWorkflowRunProperties* = Call_PutWorkflowRunProperties_603443(
    name: "putWorkflowRunProperties", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.PutWorkflowRunProperties",
    validator: validate_PutWorkflowRunProperties_603444, base: "/",
    url: url_PutWorkflowRunProperties_603445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetJobBookmark_603458 = ref object of OpenApiRestCall_601389
proc url_ResetJobBookmark_603460(protocol: Scheme; host: string; base: string;
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

proc validate_ResetJobBookmark_603459(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Resets a bookmark entry.
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
  var valid_603461 = header.getOrDefault("X-Amz-Target")
  valid_603461 = validateParameter(valid_603461, JString, required = true, default = newJString(
      "AWSGlue.ResetJobBookmark"))
  if valid_603461 != nil:
    section.add "X-Amz-Target", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Signature")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Signature", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Content-Sha256", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Date")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Date", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Credential")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Credential", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Algorithm")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Algorithm", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-SignedHeaders", valid_603468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603470: Call_ResetJobBookmark_603458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Resets a bookmark entry.
  ## 
  let valid = call_603470.validator(path, query, header, formData, body)
  let scheme = call_603470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603470.url(scheme.get, call_603470.host, call_603470.base,
                         call_603470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603470, url, valid)

proc call*(call_603471: Call_ResetJobBookmark_603458; body: JsonNode): Recallable =
  ## resetJobBookmark
  ## Resets a bookmark entry.
  ##   body: JObject (required)
  var body_603472 = newJObject()
  if body != nil:
    body_603472 = body
  result = call_603471.call(nil, nil, nil, nil, body_603472)

var resetJobBookmark* = Call_ResetJobBookmark_603458(name: "resetJobBookmark",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.ResetJobBookmark",
    validator: validate_ResetJobBookmark_603459, base: "/",
    url: url_ResetJobBookmark_603460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SearchTables_603473 = ref object of OpenApiRestCall_601389
proc url_SearchTables_603475(protocol: Scheme; host: string; base: string;
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

proc validate_SearchTables_603474(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603476 = query.getOrDefault("MaxResults")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "MaxResults", valid_603476
  var valid_603477 = query.getOrDefault("NextToken")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "NextToken", valid_603477
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
  var valid_603478 = header.getOrDefault("X-Amz-Target")
  valid_603478 = validateParameter(valid_603478, JString, required = true,
                                 default = newJString("AWSGlue.SearchTables"))
  if valid_603478 != nil:
    section.add "X-Amz-Target", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Signature")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Signature", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Content-Sha256", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Date")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Date", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Credential")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Credential", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Security-Token")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Security-Token", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-SignedHeaders", valid_603485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603487: Call_SearchTables_603473; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ## 
  let valid = call_603487.validator(path, query, header, formData, body)
  let scheme = call_603487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603487.url(scheme.get, call_603487.host, call_603487.base,
                         call_603487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603487, url, valid)

proc call*(call_603488: Call_SearchTables_603473; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## searchTables
  ## <p>Searches a set of tables based on properties in the table metadata as well as on the parent database. You can search against text or filter conditions. </p> <p>You can only get tables that you have access to based on the security policies defined in Lake Formation. You need at least a read-only access to the table for it to be returned. If you do not have access to all the columns in the table, these columns will not be searched against when returning the list of tables back to you. If you have access to the columns but not the data in the columns, those columns and the associated metadata for those columns will be included in the search. </p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603489 = newJObject()
  var body_603490 = newJObject()
  add(query_603489, "MaxResults", newJString(MaxResults))
  add(query_603489, "NextToken", newJString(NextToken))
  if body != nil:
    body_603490 = body
  result = call_603488.call(nil, query_603489, nil, nil, body_603490)

var searchTables* = Call_SearchTables_603473(name: "searchTables",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.SearchTables",
    validator: validate_SearchTables_603474, base: "/", url: url_SearchTables_603475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawler_603491 = ref object of OpenApiRestCall_601389
proc url_StartCrawler_603493(protocol: Scheme; host: string; base: string;
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

proc validate_StartCrawler_603492(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
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
  var valid_603494 = header.getOrDefault("X-Amz-Target")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = newJString("AWSGlue.StartCrawler"))
  if valid_603494 != nil:
    section.add "X-Amz-Target", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Signature")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Signature", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Content-Sha256", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Date")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Date", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Credential")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Credential", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Security-Token")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Security-Token", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Algorithm")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Algorithm", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603503: Call_StartCrawler_603491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ## 
  let valid = call_603503.validator(path, query, header, formData, body)
  let scheme = call_603503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603503.url(scheme.get, call_603503.host, call_603503.base,
                         call_603503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603503, url, valid)

proc call*(call_603504: Call_StartCrawler_603491; body: JsonNode): Recallable =
  ## startCrawler
  ## Starts a crawl using the specified crawler, regardless of what is scheduled. If the crawler is already running, returns a <a href="https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-exceptions.html#aws-glue-api-exceptions-CrawlerRunningException">CrawlerRunningException</a>.
  ##   body: JObject (required)
  var body_603505 = newJObject()
  if body != nil:
    body_603505 = body
  result = call_603504.call(nil, nil, nil, nil, body_603505)

var startCrawler* = Call_StartCrawler_603491(name: "startCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawler",
    validator: validate_StartCrawler_603492, base: "/", url: url_StartCrawler_603493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartCrawlerSchedule_603506 = ref object of OpenApiRestCall_601389
proc url_StartCrawlerSchedule_603508(protocol: Scheme; host: string; base: string;
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

proc validate_StartCrawlerSchedule_603507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
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
  var valid_603509 = header.getOrDefault("X-Amz-Target")
  valid_603509 = validateParameter(valid_603509, JString, required = true, default = newJString(
      "AWSGlue.StartCrawlerSchedule"))
  if valid_603509 != nil:
    section.add "X-Amz-Target", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Signature")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Signature", valid_603510
  var valid_603511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "X-Amz-Content-Sha256", valid_603511
  var valid_603512 = header.getOrDefault("X-Amz-Date")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Date", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Credential")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Credential", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Security-Token")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Security-Token", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Algorithm")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Algorithm", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-SignedHeaders", valid_603516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603518: Call_StartCrawlerSchedule_603506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ## 
  let valid = call_603518.validator(path, query, header, formData, body)
  let scheme = call_603518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603518.url(scheme.get, call_603518.host, call_603518.base,
                         call_603518.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603518, url, valid)

proc call*(call_603519: Call_StartCrawlerSchedule_603506; body: JsonNode): Recallable =
  ## startCrawlerSchedule
  ## Changes the schedule state of the specified crawler to <code>SCHEDULED</code>, unless the crawler is already running or the schedule state is already <code>SCHEDULED</code>.
  ##   body: JObject (required)
  var body_603520 = newJObject()
  if body != nil:
    body_603520 = body
  result = call_603519.call(nil, nil, nil, nil, body_603520)

var startCrawlerSchedule* = Call_StartCrawlerSchedule_603506(
    name: "startCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartCrawlerSchedule",
    validator: validate_StartCrawlerSchedule_603507, base: "/",
    url: url_StartCrawlerSchedule_603508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartExportLabelsTaskRun_603521 = ref object of OpenApiRestCall_601389
proc url_StartExportLabelsTaskRun_603523(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartExportLabelsTaskRun_603522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
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
  var valid_603524 = header.getOrDefault("X-Amz-Target")
  valid_603524 = validateParameter(valid_603524, JString, required = true, default = newJString(
      "AWSGlue.StartExportLabelsTaskRun"))
  if valid_603524 != nil:
    section.add "X-Amz-Target", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Signature")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Signature", valid_603525
  var valid_603526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603526 = validateParameter(valid_603526, JString, required = false,
                                 default = nil)
  if valid_603526 != nil:
    section.add "X-Amz-Content-Sha256", valid_603526
  var valid_603527 = header.getOrDefault("X-Amz-Date")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Date", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Credential")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Credential", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Security-Token")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Security-Token", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Algorithm")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Algorithm", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-SignedHeaders", valid_603531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603533: Call_StartExportLabelsTaskRun_603521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ## 
  let valid = call_603533.validator(path, query, header, formData, body)
  let scheme = call_603533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603533.url(scheme.get, call_603533.host, call_603533.base,
                         call_603533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603533, url, valid)

proc call*(call_603534: Call_StartExportLabelsTaskRun_603521; body: JsonNode): Recallable =
  ## startExportLabelsTaskRun
  ## Begins an asynchronous task to export all labeled data for a particular transform. This task is the only label-related API call that is not part of the typical active learning workflow. You typically use <code>StartExportLabelsTaskRun</code> when you want to work with all of your existing labels at the same time, such as when you want to remove or change labels that were previously submitted as truth. This API operation accepts the <code>TransformId</code> whose labels you want to export and an Amazon Simple Storage Service (Amazon S3) path to export the labels to. The operation returns a <code>TaskRunId</code>. You can check on the status of your task run by calling the <code>GetMLTaskRun</code> API.
  ##   body: JObject (required)
  var body_603535 = newJObject()
  if body != nil:
    body_603535 = body
  result = call_603534.call(nil, nil, nil, nil, body_603535)

var startExportLabelsTaskRun* = Call_StartExportLabelsTaskRun_603521(
    name: "startExportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartExportLabelsTaskRun",
    validator: validate_StartExportLabelsTaskRun_603522, base: "/",
    url: url_StartExportLabelsTaskRun_603523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImportLabelsTaskRun_603536 = ref object of OpenApiRestCall_601389
proc url_StartImportLabelsTaskRun_603538(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImportLabelsTaskRun_603537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
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
  var valid_603539 = header.getOrDefault("X-Amz-Target")
  valid_603539 = validateParameter(valid_603539, JString, required = true, default = newJString(
      "AWSGlue.StartImportLabelsTaskRun"))
  if valid_603539 != nil:
    section.add "X-Amz-Target", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Signature")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Signature", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Content-Sha256", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Date")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Date", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Credential")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Credential", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Security-Token")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Security-Token", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Algorithm")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Algorithm", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603548: Call_StartImportLabelsTaskRun_603536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ## 
  let valid = call_603548.validator(path, query, header, formData, body)
  let scheme = call_603548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603548.url(scheme.get, call_603548.host, call_603548.base,
                         call_603548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603548, url, valid)

proc call*(call_603549: Call_StartImportLabelsTaskRun_603536; body: JsonNode): Recallable =
  ## startImportLabelsTaskRun
  ## <p>Enables you to provide additional labels (examples of truth) to be used to teach the machine learning transform and improve its quality. This API operation is generally used as part of the active learning workflow that starts with the <code>StartMLLabelingSetGenerationTaskRun</code> call and that ultimately results in improving the quality of your machine learning transform. </p> <p>After the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue machine learning will have generated a series of questions for humans to answer. (Answering these questions is often called 'labeling' in the machine learning workflows). In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” After the labeling process is finished, users upload their answers/labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform use the new and improved labels and perform a higher-quality transformation.</p> <p>By default, <code>StartMLLabelingSetGenerationTaskRun</code> continually learns from and combines all labels that you upload unless you set <code>Replace</code> to true. If you set <code>Replace</code> to true, <code>StartImportLabelsTaskRun</code> deletes and forgets all previously uploaded labels and learns only from the exact set that you upload. Replacing labels can be helpful if you realize that you previously uploaded incorrect labels, and you believe that they are having a negative effect on your transform quality.</p> <p>You can check on the status of your task run by calling the <code>GetMLTaskRun</code> operation. </p>
  ##   body: JObject (required)
  var body_603550 = newJObject()
  if body != nil:
    body_603550 = body
  result = call_603549.call(nil, nil, nil, nil, body_603550)

var startImportLabelsTaskRun* = Call_StartImportLabelsTaskRun_603536(
    name: "startImportLabelsTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartImportLabelsTaskRun",
    validator: validate_StartImportLabelsTaskRun_603537, base: "/",
    url: url_StartImportLabelsTaskRun_603538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJobRun_603551 = ref object of OpenApiRestCall_601389
proc url_StartJobRun_603553(protocol: Scheme; host: string; base: string;
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

proc validate_StartJobRun_603552(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job run using a job definition.
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
  var valid_603554 = header.getOrDefault("X-Amz-Target")
  valid_603554 = validateParameter(valid_603554, JString, required = true,
                                 default = newJString("AWSGlue.StartJobRun"))
  if valid_603554 != nil:
    section.add "X-Amz-Target", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Signature")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Signature", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Content-Sha256", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Date")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Date", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Credential")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Credential", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Security-Token")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Security-Token", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Algorithm")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Algorithm", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603563: Call_StartJobRun_603551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job run using a job definition.
  ## 
  let valid = call_603563.validator(path, query, header, formData, body)
  let scheme = call_603563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603563.url(scheme.get, call_603563.host, call_603563.base,
                         call_603563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603563, url, valid)

proc call*(call_603564: Call_StartJobRun_603551; body: JsonNode): Recallable =
  ## startJobRun
  ## Starts a job run using a job definition.
  ##   body: JObject (required)
  var body_603565 = newJObject()
  if body != nil:
    body_603565 = body
  result = call_603564.call(nil, nil, nil, nil, body_603565)

var startJobRun* = Call_StartJobRun_603551(name: "startJobRun",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StartJobRun",
                                        validator: validate_StartJobRun_603552,
                                        base: "/", url: url_StartJobRun_603553,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLEvaluationTaskRun_603566 = ref object of OpenApiRestCall_601389
proc url_StartMLEvaluationTaskRun_603568(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartMLEvaluationTaskRun_603567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
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
  var valid_603569 = header.getOrDefault("X-Amz-Target")
  valid_603569 = validateParameter(valid_603569, JString, required = true, default = newJString(
      "AWSGlue.StartMLEvaluationTaskRun"))
  if valid_603569 != nil:
    section.add "X-Amz-Target", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Signature")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Signature", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Date")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Date", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Credential")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Credential", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Security-Token")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Security-Token", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603578: Call_StartMLEvaluationTaskRun_603566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ## 
  let valid = call_603578.validator(path, query, header, formData, body)
  let scheme = call_603578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603578.url(scheme.get, call_603578.host, call_603578.base,
                         call_603578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603578, url, valid)

proc call*(call_603579: Call_StartMLEvaluationTaskRun_603566; body: JsonNode): Recallable =
  ## startMLEvaluationTaskRun
  ## <p>Starts a task to estimate the quality of the transform. </p> <p>When you provide label sets as examples of truth, AWS Glue machine learning uses some of those examples to learn from them. The rest of the labels are used as a test to estimate quality.</p> <p>Returns a unique identifier for the run. You can call <code>GetMLTaskRun</code> to get more information about the stats of the <code>EvaluationTaskRun</code>.</p>
  ##   body: JObject (required)
  var body_603580 = newJObject()
  if body != nil:
    body_603580 = body
  result = call_603579.call(nil, nil, nil, nil, body_603580)

var startMLEvaluationTaskRun* = Call_StartMLEvaluationTaskRun_603566(
    name: "startMLEvaluationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLEvaluationTaskRun",
    validator: validate_StartMLEvaluationTaskRun_603567, base: "/",
    url: url_StartMLEvaluationTaskRun_603568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMLLabelingSetGenerationTaskRun_603581 = ref object of OpenApiRestCall_601389
proc url_StartMLLabelingSetGenerationTaskRun_603583(protocol: Scheme; host: string;
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

proc validate_StartMLLabelingSetGenerationTaskRun_603582(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
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
  var valid_603584 = header.getOrDefault("X-Amz-Target")
  valid_603584 = validateParameter(valid_603584, JString, required = true, default = newJString(
      "AWSGlue.StartMLLabelingSetGenerationTaskRun"))
  if valid_603584 != nil:
    section.add "X-Amz-Target", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Signature")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Signature", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Date")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Date", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Security-Token")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Security-Token", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Algorithm")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Algorithm", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-SignedHeaders", valid_603591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603593: Call_StartMLLabelingSetGenerationTaskRun_603581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ## 
  let valid = call_603593.validator(path, query, header, formData, body)
  let scheme = call_603593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603593.url(scheme.get, call_603593.host, call_603593.base,
                         call_603593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603593, url, valid)

proc call*(call_603594: Call_StartMLLabelingSetGenerationTaskRun_603581;
          body: JsonNode): Recallable =
  ## startMLLabelingSetGenerationTaskRun
  ## <p>Starts the active learning workflow for your machine learning transform to improve the transform's quality by generating label sets and adding labels.</p> <p>When the <code>StartMLLabelingSetGenerationTaskRun</code> finishes, AWS Glue will have generated a "labeling set" or a set of questions for humans to answer.</p> <p>In the case of the <code>FindMatches</code> transform, these questions are of the form, “What is the correct way to group these rows together into groups composed entirely of matching records?” </p> <p>After the labeling process is finished, you can upload your labels with a call to <code>StartImportLabelsTaskRun</code>. After <code>StartImportLabelsTaskRun</code> finishes, all future runs of the machine learning transform will use the new and improved labels and perform a higher-quality transformation.</p>
  ##   body: JObject (required)
  var body_603595 = newJObject()
  if body != nil:
    body_603595 = body
  result = call_603594.call(nil, nil, nil, nil, body_603595)

var startMLLabelingSetGenerationTaskRun* = Call_StartMLLabelingSetGenerationTaskRun_603581(
    name: "startMLLabelingSetGenerationTaskRun", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartMLLabelingSetGenerationTaskRun",
    validator: validate_StartMLLabelingSetGenerationTaskRun_603582, base: "/",
    url: url_StartMLLabelingSetGenerationTaskRun_603583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTrigger_603596 = ref object of OpenApiRestCall_601389
proc url_StartTrigger_603598(protocol: Scheme; host: string; base: string;
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

proc validate_StartTrigger_603597(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
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
  var valid_603599 = header.getOrDefault("X-Amz-Target")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = newJString("AWSGlue.StartTrigger"))
  if valid_603599 != nil:
    section.add "X-Amz-Target", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Signature")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Signature", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Date")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Date", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Credential")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Credential", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Security-Token")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Security-Token", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Algorithm")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Algorithm", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-SignedHeaders", valid_603606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603608: Call_StartTrigger_603596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ## 
  let valid = call_603608.validator(path, query, header, formData, body)
  let scheme = call_603608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603608.url(scheme.get, call_603608.host, call_603608.base,
                         call_603608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603608, url, valid)

proc call*(call_603609: Call_StartTrigger_603596; body: JsonNode): Recallable =
  ## startTrigger
  ## Starts an existing trigger. See <a href="https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html">Triggering Jobs</a> for information about how different types of trigger are started.
  ##   body: JObject (required)
  var body_603610 = newJObject()
  if body != nil:
    body_603610 = body
  result = call_603609.call(nil, nil, nil, nil, body_603610)

var startTrigger* = Call_StartTrigger_603596(name: "startTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartTrigger",
    validator: validate_StartTrigger_603597, base: "/", url: url_StartTrigger_603598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartWorkflowRun_603611 = ref object of OpenApiRestCall_601389
proc url_StartWorkflowRun_603613(protocol: Scheme; host: string; base: string;
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

proc validate_StartWorkflowRun_603612(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Starts a new run of the specified workflow.
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
  var valid_603614 = header.getOrDefault("X-Amz-Target")
  valid_603614 = validateParameter(valid_603614, JString, required = true, default = newJString(
      "AWSGlue.StartWorkflowRun"))
  if valid_603614 != nil:
    section.add "X-Amz-Target", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Signature")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Signature", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Content-Sha256", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Date")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Date", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Credential")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Credential", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Security-Token")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Security-Token", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Algorithm")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Algorithm", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603623: Call_StartWorkflowRun_603611; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new run of the specified workflow.
  ## 
  let valid = call_603623.validator(path, query, header, formData, body)
  let scheme = call_603623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603623.url(scheme.get, call_603623.host, call_603623.base,
                         call_603623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603623, url, valid)

proc call*(call_603624: Call_StartWorkflowRun_603611; body: JsonNode): Recallable =
  ## startWorkflowRun
  ## Starts a new run of the specified workflow.
  ##   body: JObject (required)
  var body_603625 = newJObject()
  if body != nil:
    body_603625 = body
  result = call_603624.call(nil, nil, nil, nil, body_603625)

var startWorkflowRun* = Call_StartWorkflowRun_603611(name: "startWorkflowRun",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StartWorkflowRun",
    validator: validate_StartWorkflowRun_603612, base: "/",
    url: url_StartWorkflowRun_603613, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawler_603626 = ref object of OpenApiRestCall_601389
proc url_StopCrawler_603628(protocol: Scheme; host: string; base: string;
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

proc validate_StopCrawler_603627(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## If the specified crawler is running, stops the crawl.
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
  var valid_603629 = header.getOrDefault("X-Amz-Target")
  valid_603629 = validateParameter(valid_603629, JString, required = true,
                                 default = newJString("AWSGlue.StopCrawler"))
  if valid_603629 != nil:
    section.add "X-Amz-Target", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Signature")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Signature", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Content-Sha256", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Date")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Date", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Credential")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Credential", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Security-Token")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Security-Token", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Algorithm")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Algorithm", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603638: Call_StopCrawler_603626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## If the specified crawler is running, stops the crawl.
  ## 
  let valid = call_603638.validator(path, query, header, formData, body)
  let scheme = call_603638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603638.url(scheme.get, call_603638.host, call_603638.base,
                         call_603638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603638, url, valid)

proc call*(call_603639: Call_StopCrawler_603626; body: JsonNode): Recallable =
  ## stopCrawler
  ## If the specified crawler is running, stops the crawl.
  ##   body: JObject (required)
  var body_603640 = newJObject()
  if body != nil:
    body_603640 = body
  result = call_603639.call(nil, nil, nil, nil, body_603640)

var stopCrawler* = Call_StopCrawler_603626(name: "stopCrawler",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopCrawler",
                                        validator: validate_StopCrawler_603627,
                                        base: "/", url: url_StopCrawler_603628,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopCrawlerSchedule_603641 = ref object of OpenApiRestCall_601389
proc url_StopCrawlerSchedule_603643(protocol: Scheme; host: string; base: string;
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

proc validate_StopCrawlerSchedule_603642(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
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
  var valid_603644 = header.getOrDefault("X-Amz-Target")
  valid_603644 = validateParameter(valid_603644, JString, required = true, default = newJString(
      "AWSGlue.StopCrawlerSchedule"))
  if valid_603644 != nil:
    section.add "X-Amz-Target", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Signature")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Signature", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Content-Sha256", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-Date")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-Date", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Credential")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Credential", valid_603648
  var valid_603649 = header.getOrDefault("X-Amz-Security-Token")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Security-Token", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Algorithm")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Algorithm", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-SignedHeaders", valid_603651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603653: Call_StopCrawlerSchedule_603641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ## 
  let valid = call_603653.validator(path, query, header, formData, body)
  let scheme = call_603653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603653.url(scheme.get, call_603653.host, call_603653.base,
                         call_603653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603653, url, valid)

proc call*(call_603654: Call_StopCrawlerSchedule_603641; body: JsonNode): Recallable =
  ## stopCrawlerSchedule
  ## Sets the schedule state of the specified crawler to <code>NOT_SCHEDULED</code>, but does not stop the crawler if it is already running.
  ##   body: JObject (required)
  var body_603655 = newJObject()
  if body != nil:
    body_603655 = body
  result = call_603654.call(nil, nil, nil, nil, body_603655)

var stopCrawlerSchedule* = Call_StopCrawlerSchedule_603641(
    name: "stopCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.StopCrawlerSchedule",
    validator: validate_StopCrawlerSchedule_603642, base: "/",
    url: url_StopCrawlerSchedule_603643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTrigger_603656 = ref object of OpenApiRestCall_601389
proc url_StopTrigger_603658(protocol: Scheme; host: string; base: string;
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

proc validate_StopTrigger_603657(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a specified trigger.
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
  var valid_603659 = header.getOrDefault("X-Amz-Target")
  valid_603659 = validateParameter(valid_603659, JString, required = true,
                                 default = newJString("AWSGlue.StopTrigger"))
  if valid_603659 != nil:
    section.add "X-Amz-Target", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Signature")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Signature", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Content-Sha256", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Date")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Date", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Credential")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Credential", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Security-Token")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Security-Token", valid_603664
  var valid_603665 = header.getOrDefault("X-Amz-Algorithm")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Algorithm", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-SignedHeaders", valid_603666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603668: Call_StopTrigger_603656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a specified trigger.
  ## 
  let valid = call_603668.validator(path, query, header, formData, body)
  let scheme = call_603668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603668.url(scheme.get, call_603668.host, call_603668.base,
                         call_603668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603668, url, valid)

proc call*(call_603669: Call_StopTrigger_603656; body: JsonNode): Recallable =
  ## stopTrigger
  ## Stops a specified trigger.
  ##   body: JObject (required)
  var body_603670 = newJObject()
  if body != nil:
    body_603670 = body
  result = call_603669.call(nil, nil, nil, nil, body_603670)

var stopTrigger* = Call_StopTrigger_603656(name: "stopTrigger",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.StopTrigger",
                                        validator: validate_StopTrigger_603657,
                                        base: "/", url: url_StopTrigger_603658,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603671 = ref object of OpenApiRestCall_601389
proc url_TagResource_603673(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603672(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
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
  var valid_603674 = header.getOrDefault("X-Amz-Target")
  valid_603674 = validateParameter(valid_603674, JString, required = true,
                                 default = newJString("AWSGlue.TagResource"))
  if valid_603674 != nil:
    section.add "X-Amz-Target", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Signature")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Signature", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Content-Sha256", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Date")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Date", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Credential")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Credential", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Security-Token")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Security-Token", valid_603679
  var valid_603680 = header.getOrDefault("X-Amz-Algorithm")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Algorithm", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-SignedHeaders", valid_603681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603683: Call_TagResource_603671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ## 
  let valid = call_603683.validator(path, query, header, formData, body)
  let scheme = call_603683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603683.url(scheme.get, call_603683.host, call_603683.base,
                         call_603683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603683, url, valid)

proc call*(call_603684: Call_TagResource_603671; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource. A tag is a label you can assign to an AWS resource. In AWS Glue, you can tag only certain resources. For information about what resources you can tag, see <a href="https://docs.aws.amazon.com/glue/latest/dg/monitor-tags.html">AWS Tags in AWS Glue</a>.
  ##   body: JObject (required)
  var body_603685 = newJObject()
  if body != nil:
    body_603685 = body
  result = call_603684.call(nil, nil, nil, nil, body_603685)

var tagResource* = Call_TagResource_603671(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.TagResource",
                                        validator: validate_TagResource_603672,
                                        base: "/", url: url_TagResource_603673,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603686 = ref object of OpenApiRestCall_601389
proc url_UntagResource_603688(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603687(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
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
  var valid_603689 = header.getOrDefault("X-Amz-Target")
  valid_603689 = validateParameter(valid_603689, JString, required = true,
                                 default = newJString("AWSGlue.UntagResource"))
  if valid_603689 != nil:
    section.add "X-Amz-Target", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Signature")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Signature", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Content-Sha256", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Date")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Date", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Credential")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Credential", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Security-Token")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Security-Token", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Algorithm")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Algorithm", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_UntagResource_603686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603698, url, valid)

proc call*(call_603699: Call_UntagResource_603686; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   body: JObject (required)
  var body_603700 = newJObject()
  if body != nil:
    body_603700 = body
  result = call_603699.call(nil, nil, nil, nil, body_603700)

var untagResource* = Call_UntagResource_603686(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UntagResource",
    validator: validate_UntagResource_603687, base: "/", url: url_UntagResource_603688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClassifier_603701 = ref object of OpenApiRestCall_601389
proc url_UpdateClassifier_603703(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClassifier_603702(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
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
  var valid_603704 = header.getOrDefault("X-Amz-Target")
  valid_603704 = validateParameter(valid_603704, JString, required = true, default = newJString(
      "AWSGlue.UpdateClassifier"))
  if valid_603704 != nil:
    section.add "X-Amz-Target", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Signature")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Signature", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Content-Sha256", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Date")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Date", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Credential")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Credential", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Security-Token")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Security-Token", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Algorithm")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Algorithm", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603713: Call_UpdateClassifier_603701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ## 
  let valid = call_603713.validator(path, query, header, formData, body)
  let scheme = call_603713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603713.url(scheme.get, call_603713.host, call_603713.base,
                         call_603713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603713, url, valid)

proc call*(call_603714: Call_UpdateClassifier_603701; body: JsonNode): Recallable =
  ## updateClassifier
  ## Modifies an existing classifier (a <code>GrokClassifier</code>, an <code>XMLClassifier</code>, a <code>JsonClassifier</code>, or a <code>CsvClassifier</code>, depending on which field is present).
  ##   body: JObject (required)
  var body_603715 = newJObject()
  if body != nil:
    body_603715 = body
  result = call_603714.call(nil, nil, nil, nil, body_603715)

var updateClassifier* = Call_UpdateClassifier_603701(name: "updateClassifier",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateClassifier",
    validator: validate_UpdateClassifier_603702, base: "/",
    url: url_UpdateClassifier_603703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConnection_603716 = ref object of OpenApiRestCall_601389
proc url_UpdateConnection_603718(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateConnection_603717(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a connection definition in the Data Catalog.
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
  var valid_603719 = header.getOrDefault("X-Amz-Target")
  valid_603719 = validateParameter(valid_603719, JString, required = true, default = newJString(
      "AWSGlue.UpdateConnection"))
  if valid_603719 != nil:
    section.add "X-Amz-Target", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Signature")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Signature", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Content-Sha256", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Date")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Date", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Credential")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Credential", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Security-Token")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Security-Token", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Algorithm")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Algorithm", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-SignedHeaders", valid_603726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603728: Call_UpdateConnection_603716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a connection definition in the Data Catalog.
  ## 
  let valid = call_603728.validator(path, query, header, formData, body)
  let scheme = call_603728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603728.url(scheme.get, call_603728.host, call_603728.base,
                         call_603728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603728, url, valid)

proc call*(call_603729: Call_UpdateConnection_603716; body: JsonNode): Recallable =
  ## updateConnection
  ## Updates a connection definition in the Data Catalog.
  ##   body: JObject (required)
  var body_603730 = newJObject()
  if body != nil:
    body_603730 = body
  result = call_603729.call(nil, nil, nil, nil, body_603730)

var updateConnection* = Call_UpdateConnection_603716(name: "updateConnection",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateConnection",
    validator: validate_UpdateConnection_603717, base: "/",
    url: url_UpdateConnection_603718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawler_603731 = ref object of OpenApiRestCall_601389
proc url_UpdateCrawler_603733(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCrawler_603732(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
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
  var valid_603734 = header.getOrDefault("X-Amz-Target")
  valid_603734 = validateParameter(valid_603734, JString, required = true,
                                 default = newJString("AWSGlue.UpdateCrawler"))
  if valid_603734 != nil:
    section.add "X-Amz-Target", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Signature")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Signature", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Content-Sha256", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-Date")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Date", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Credential")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Credential", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Security-Token")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Security-Token", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Algorithm")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Algorithm", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-SignedHeaders", valid_603741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603743: Call_UpdateCrawler_603731; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ## 
  let valid = call_603743.validator(path, query, header, formData, body)
  let scheme = call_603743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603743.url(scheme.get, call_603743.host, call_603743.base,
                         call_603743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603743, url, valid)

proc call*(call_603744: Call_UpdateCrawler_603731; body: JsonNode): Recallable =
  ## updateCrawler
  ## Updates a crawler. If a crawler is running, you must stop it using <code>StopCrawler</code> before updating it.
  ##   body: JObject (required)
  var body_603745 = newJObject()
  if body != nil:
    body_603745 = body
  result = call_603744.call(nil, nil, nil, nil, body_603745)

var updateCrawler* = Call_UpdateCrawler_603731(name: "updateCrawler",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawler",
    validator: validate_UpdateCrawler_603732, base: "/", url: url_UpdateCrawler_603733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCrawlerSchedule_603746 = ref object of OpenApiRestCall_601389
proc url_UpdateCrawlerSchedule_603748(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateCrawlerSchedule_603747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
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
  var valid_603749 = header.getOrDefault("X-Amz-Target")
  valid_603749 = validateParameter(valid_603749, JString, required = true, default = newJString(
      "AWSGlue.UpdateCrawlerSchedule"))
  if valid_603749 != nil:
    section.add "X-Amz-Target", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Signature")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Signature", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Content-Sha256", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Date")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Date", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Credential")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Credential", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Security-Token")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Security-Token", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Algorithm")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Algorithm", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-SignedHeaders", valid_603756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603758: Call_UpdateCrawlerSchedule_603746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ## 
  let valid = call_603758.validator(path, query, header, formData, body)
  let scheme = call_603758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603758.url(scheme.get, call_603758.host, call_603758.base,
                         call_603758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603758, url, valid)

proc call*(call_603759: Call_UpdateCrawlerSchedule_603746; body: JsonNode): Recallable =
  ## updateCrawlerSchedule
  ## Updates the schedule of a crawler using a <code>cron</code> expression. 
  ##   body: JObject (required)
  var body_603760 = newJObject()
  if body != nil:
    body_603760 = body
  result = call_603759.call(nil, nil, nil, nil, body_603760)

var updateCrawlerSchedule* = Call_UpdateCrawlerSchedule_603746(
    name: "updateCrawlerSchedule", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateCrawlerSchedule",
    validator: validate_UpdateCrawlerSchedule_603747, base: "/",
    url: url_UpdateCrawlerSchedule_603748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatabase_603761 = ref object of OpenApiRestCall_601389
proc url_UpdateDatabase_603763(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDatabase_603762(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing database definition in a Data Catalog.
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
  var valid_603764 = header.getOrDefault("X-Amz-Target")
  valid_603764 = validateParameter(valid_603764, JString, required = true,
                                 default = newJString("AWSGlue.UpdateDatabase"))
  if valid_603764 != nil:
    section.add "X-Amz-Target", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Signature")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Signature", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Content-Sha256", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Date")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Date", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Credential")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Credential", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Security-Token")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Security-Token", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-Algorithm")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-Algorithm", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-SignedHeaders", valid_603771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603773: Call_UpdateDatabase_603761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing database definition in a Data Catalog.
  ## 
  let valid = call_603773.validator(path, query, header, formData, body)
  let scheme = call_603773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603773.url(scheme.get, call_603773.host, call_603773.base,
                         call_603773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603773, url, valid)

proc call*(call_603774: Call_UpdateDatabase_603761; body: JsonNode): Recallable =
  ## updateDatabase
  ## Updates an existing database definition in a Data Catalog.
  ##   body: JObject (required)
  var body_603775 = newJObject()
  if body != nil:
    body_603775 = body
  result = call_603774.call(nil, nil, nil, nil, body_603775)

var updateDatabase* = Call_UpdateDatabase_603761(name: "updateDatabase",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDatabase",
    validator: validate_UpdateDatabase_603762, base: "/", url: url_UpdateDatabase_603763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDevEndpoint_603776 = ref object of OpenApiRestCall_601389
proc url_UpdateDevEndpoint_603778(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDevEndpoint_603777(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates a specified development endpoint.
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
  var valid_603779 = header.getOrDefault("X-Amz-Target")
  valid_603779 = validateParameter(valid_603779, JString, required = true, default = newJString(
      "AWSGlue.UpdateDevEndpoint"))
  if valid_603779 != nil:
    section.add "X-Amz-Target", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Signature")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Signature", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Content-Sha256", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Date")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Date", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Credential")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Credential", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Security-Token")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Security-Token", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-Algorithm")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-Algorithm", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-SignedHeaders", valid_603786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603788: Call_UpdateDevEndpoint_603776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a specified development endpoint.
  ## 
  let valid = call_603788.validator(path, query, header, formData, body)
  let scheme = call_603788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603788.url(scheme.get, call_603788.host, call_603788.base,
                         call_603788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603788, url, valid)

proc call*(call_603789: Call_UpdateDevEndpoint_603776; body: JsonNode): Recallable =
  ## updateDevEndpoint
  ## Updates a specified development endpoint.
  ##   body: JObject (required)
  var body_603790 = newJObject()
  if body != nil:
    body_603790 = body
  result = call_603789.call(nil, nil, nil, nil, body_603790)

var updateDevEndpoint* = Call_UpdateDevEndpoint_603776(name: "updateDevEndpoint",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateDevEndpoint",
    validator: validate_UpdateDevEndpoint_603777, base: "/",
    url: url_UpdateDevEndpoint_603778, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_603791 = ref object of OpenApiRestCall_601389
proc url_UpdateJob_603793(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateJob_603792(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing job definition.
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
  var valid_603794 = header.getOrDefault("X-Amz-Target")
  valid_603794 = validateParameter(valid_603794, JString, required = true,
                                 default = newJString("AWSGlue.UpdateJob"))
  if valid_603794 != nil:
    section.add "X-Amz-Target", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Signature")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Signature", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Content-Sha256", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Date")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Date", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Credential")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Credential", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Security-Token")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Security-Token", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-SignedHeaders", valid_603801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603803: Call_UpdateJob_603791; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing job definition.
  ## 
  let valid = call_603803.validator(path, query, header, formData, body)
  let scheme = call_603803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603803.url(scheme.get, call_603803.host, call_603803.base,
                         call_603803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603803, url, valid)

proc call*(call_603804: Call_UpdateJob_603791; body: JsonNode): Recallable =
  ## updateJob
  ## Updates an existing job definition.
  ##   body: JObject (required)
  var body_603805 = newJObject()
  if body != nil:
    body_603805 = body
  result = call_603804.call(nil, nil, nil, nil, body_603805)

var updateJob* = Call_UpdateJob_603791(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "glue.amazonaws.com",
                                    route: "/#X-Amz-Target=AWSGlue.UpdateJob",
                                    validator: validate_UpdateJob_603792,
                                    base: "/", url: url_UpdateJob_603793,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMLTransform_603806 = ref object of OpenApiRestCall_601389
proc url_UpdateMLTransform_603808(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMLTransform_603807(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
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
  var valid_603809 = header.getOrDefault("X-Amz-Target")
  valid_603809 = validateParameter(valid_603809, JString, required = true, default = newJString(
      "AWSGlue.UpdateMLTransform"))
  if valid_603809 != nil:
    section.add "X-Amz-Target", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Signature")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Signature", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Content-Sha256", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-Date")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Date", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Credential")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Credential", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Security-Token")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Security-Token", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Algorithm")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Algorithm", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-SignedHeaders", valid_603816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603818: Call_UpdateMLTransform_603806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ## 
  let valid = call_603818.validator(path, query, header, formData, body)
  let scheme = call_603818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603818.url(scheme.get, call_603818.host, call_603818.base,
                         call_603818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603818, url, valid)

proc call*(call_603819: Call_UpdateMLTransform_603806; body: JsonNode): Recallable =
  ## updateMLTransform
  ## <p>Updates an existing machine learning transform. Call this operation to tune the algorithm parameters to achieve better results.</p> <p>After calling this operation, you can call the <code>StartMLEvaluationTaskRun</code> operation to assess how well your new parameters achieved your goals (such as improving the quality of your machine learning transform, or making it more cost-effective).</p>
  ##   body: JObject (required)
  var body_603820 = newJObject()
  if body != nil:
    body_603820 = body
  result = call_603819.call(nil, nil, nil, nil, body_603820)

var updateMLTransform* = Call_UpdateMLTransform_603806(name: "updateMLTransform",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateMLTransform",
    validator: validate_UpdateMLTransform_603807, base: "/",
    url: url_UpdateMLTransform_603808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePartition_603821 = ref object of OpenApiRestCall_601389
proc url_UpdatePartition_603823(protocol: Scheme; host: string; base: string;
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

proc validate_UpdatePartition_603822(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a partition.
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
  var valid_603824 = header.getOrDefault("X-Amz-Target")
  valid_603824 = validateParameter(valid_603824, JString, required = true, default = newJString(
      "AWSGlue.UpdatePartition"))
  if valid_603824 != nil:
    section.add "X-Amz-Target", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Signature")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Signature", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Content-Sha256", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Date")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Date", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Credential")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Credential", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Security-Token")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Security-Token", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Algorithm")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Algorithm", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-SignedHeaders", valid_603831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603833: Call_UpdatePartition_603821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a partition.
  ## 
  let valid = call_603833.validator(path, query, header, formData, body)
  let scheme = call_603833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603833.url(scheme.get, call_603833.host, call_603833.base,
                         call_603833.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603833, url, valid)

proc call*(call_603834: Call_UpdatePartition_603821; body: JsonNode): Recallable =
  ## updatePartition
  ## Updates a partition.
  ##   body: JObject (required)
  var body_603835 = newJObject()
  if body != nil:
    body_603835 = body
  result = call_603834.call(nil, nil, nil, nil, body_603835)

var updatePartition* = Call_UpdatePartition_603821(name: "updatePartition",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdatePartition",
    validator: validate_UpdatePartition_603822, base: "/", url: url_UpdatePartition_603823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTable_603836 = ref object of OpenApiRestCall_601389
proc url_UpdateTable_603838(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTable_603837(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a metadata table in the Data Catalog.
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
  var valid_603839 = header.getOrDefault("X-Amz-Target")
  valid_603839 = validateParameter(valid_603839, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTable"))
  if valid_603839 != nil:
    section.add "X-Amz-Target", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Signature")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Signature", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Content-Sha256", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Date")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Date", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Credential")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Credential", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Security-Token")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Security-Token", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Algorithm")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Algorithm", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-SignedHeaders", valid_603846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603848: Call_UpdateTable_603836; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a metadata table in the Data Catalog.
  ## 
  let valid = call_603848.validator(path, query, header, formData, body)
  let scheme = call_603848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603848.url(scheme.get, call_603848.host, call_603848.base,
                         call_603848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603848, url, valid)

proc call*(call_603849: Call_UpdateTable_603836; body: JsonNode): Recallable =
  ## updateTable
  ## Updates a metadata table in the Data Catalog.
  ##   body: JObject (required)
  var body_603850 = newJObject()
  if body != nil:
    body_603850 = body
  result = call_603849.call(nil, nil, nil, nil, body_603850)

var updateTable* = Call_UpdateTable_603836(name: "updateTable",
                                        meth: HttpMethod.HttpPost,
                                        host: "glue.amazonaws.com", route: "/#X-Amz-Target=AWSGlue.UpdateTable",
                                        validator: validate_UpdateTable_603837,
                                        base: "/", url: url_UpdateTable_603838,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrigger_603851 = ref object of OpenApiRestCall_601389
proc url_UpdateTrigger_603853(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrigger_603852(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a trigger definition.
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
  var valid_603854 = header.getOrDefault("X-Amz-Target")
  valid_603854 = validateParameter(valid_603854, JString, required = true,
                                 default = newJString("AWSGlue.UpdateTrigger"))
  if valid_603854 != nil:
    section.add "X-Amz-Target", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Signature")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Signature", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Content-Sha256", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-Date")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Date", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Credential")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Credential", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Security-Token")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Security-Token", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Algorithm")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Algorithm", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-SignedHeaders", valid_603861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603863: Call_UpdateTrigger_603851; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a trigger definition.
  ## 
  let valid = call_603863.validator(path, query, header, formData, body)
  let scheme = call_603863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603863.url(scheme.get, call_603863.host, call_603863.base,
                         call_603863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603863, url, valid)

proc call*(call_603864: Call_UpdateTrigger_603851; body: JsonNode): Recallable =
  ## updateTrigger
  ## Updates a trigger definition.
  ##   body: JObject (required)
  var body_603865 = newJObject()
  if body != nil:
    body_603865 = body
  result = call_603864.call(nil, nil, nil, nil, body_603865)

var updateTrigger* = Call_UpdateTrigger_603851(name: "updateTrigger",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateTrigger",
    validator: validate_UpdateTrigger_603852, base: "/", url: url_UpdateTrigger_603853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUserDefinedFunction_603866 = ref object of OpenApiRestCall_601389
proc url_UpdateUserDefinedFunction_603868(protocol: Scheme; host: string;
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

proc validate_UpdateUserDefinedFunction_603867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing function definition in the Data Catalog.
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
  var valid_603869 = header.getOrDefault("X-Amz-Target")
  valid_603869 = validateParameter(valid_603869, JString, required = true, default = newJString(
      "AWSGlue.UpdateUserDefinedFunction"))
  if valid_603869 != nil:
    section.add "X-Amz-Target", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Signature")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Signature", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Content-Sha256", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-Date")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Date", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Credential")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Credential", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Security-Token")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Security-Token", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Algorithm")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Algorithm", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-SignedHeaders", valid_603876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603878: Call_UpdateUserDefinedFunction_603866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing function definition in the Data Catalog.
  ## 
  let valid = call_603878.validator(path, query, header, formData, body)
  let scheme = call_603878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603878.url(scheme.get, call_603878.host, call_603878.base,
                         call_603878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603878, url, valid)

proc call*(call_603879: Call_UpdateUserDefinedFunction_603866; body: JsonNode): Recallable =
  ## updateUserDefinedFunction
  ## Updates an existing function definition in the Data Catalog.
  ##   body: JObject (required)
  var body_603880 = newJObject()
  if body != nil:
    body_603880 = body
  result = call_603879.call(nil, nil, nil, nil, body_603880)

var updateUserDefinedFunction* = Call_UpdateUserDefinedFunction_603866(
    name: "updateUserDefinedFunction", meth: HttpMethod.HttpPost,
    host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateUserDefinedFunction",
    validator: validate_UpdateUserDefinedFunction_603867, base: "/",
    url: url_UpdateUserDefinedFunction_603868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWorkflow_603881 = ref object of OpenApiRestCall_601389
proc url_UpdateWorkflow_603883(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateWorkflow_603882(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an existing workflow.
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
  var valid_603884 = header.getOrDefault("X-Amz-Target")
  valid_603884 = validateParameter(valid_603884, JString, required = true,
                                 default = newJString("AWSGlue.UpdateWorkflow"))
  if valid_603884 != nil:
    section.add "X-Amz-Target", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Signature")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Signature", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Content-Sha256", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-Date")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-Date", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Credential")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Credential", valid_603888
  var valid_603889 = header.getOrDefault("X-Amz-Security-Token")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "X-Amz-Security-Token", valid_603889
  var valid_603890 = header.getOrDefault("X-Amz-Algorithm")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "X-Amz-Algorithm", valid_603890
  var valid_603891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "X-Amz-SignedHeaders", valid_603891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_UpdateWorkflow_603881; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing workflow.
  ## 
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603893, url, valid)

proc call*(call_603894: Call_UpdateWorkflow_603881; body: JsonNode): Recallable =
  ## updateWorkflow
  ## Updates an existing workflow.
  ##   body: JObject (required)
  var body_603895 = newJObject()
  if body != nil:
    body_603895 = body
  result = call_603894.call(nil, nil, nil, nil, body_603895)

var updateWorkflow* = Call_UpdateWorkflow_603881(name: "updateWorkflow",
    meth: HttpMethod.HttpPost, host: "glue.amazonaws.com",
    route: "/#X-Amz-Target=AWSGlue.UpdateWorkflow",
    validator: validate_UpdateWorkflow_603882, base: "/", url: url_UpdateWorkflow_603883,
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
