
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Translate
## version: 2017-07-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Provides translation between one source language and another of the same set of languages.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/translate/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "translate.ap-northeast-1.amazonaws.com", "ap-southeast-1": "translate.ap-southeast-1.amazonaws.com",
                           "us-west-2": "translate.us-west-2.amazonaws.com",
                           "eu-west-2": "translate.eu-west-2.amazonaws.com", "ap-northeast-3": "translate.ap-northeast-3.amazonaws.com", "eu-central-1": "translate.eu-central-1.amazonaws.com",
                           "us-east-2": "translate.us-east-2.amazonaws.com",
                           "us-east-1": "translate.us-east-1.amazonaws.com", "cn-northwest-1": "translate.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "translate.ap-south-1.amazonaws.com",
                           "eu-north-1": "translate.eu-north-1.amazonaws.com", "ap-northeast-2": "translate.ap-northeast-2.amazonaws.com",
                           "us-west-1": "translate.us-west-1.amazonaws.com", "us-gov-east-1": "translate.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "translate.eu-west-3.amazonaws.com", "cn-north-1": "translate.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "translate.sa-east-1.amazonaws.com",
                           "eu-west-1": "translate.eu-west-1.amazonaws.com", "us-gov-west-1": "translate.us-gov-west-1.amazonaws.com", "ap-southeast-2": "translate.ap-southeast-2.amazonaws.com", "ca-central-1": "translate.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "translate.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "translate.ap-southeast-1.amazonaws.com",
      "us-west-2": "translate.us-west-2.amazonaws.com",
      "eu-west-2": "translate.eu-west-2.amazonaws.com",
      "ap-northeast-3": "translate.ap-northeast-3.amazonaws.com",
      "eu-central-1": "translate.eu-central-1.amazonaws.com",
      "us-east-2": "translate.us-east-2.amazonaws.com",
      "us-east-1": "translate.us-east-1.amazonaws.com",
      "cn-northwest-1": "translate.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "translate.ap-south-1.amazonaws.com",
      "eu-north-1": "translate.eu-north-1.amazonaws.com",
      "ap-northeast-2": "translate.ap-northeast-2.amazonaws.com",
      "us-west-1": "translate.us-west-1.amazonaws.com",
      "us-gov-east-1": "translate.us-gov-east-1.amazonaws.com",
      "eu-west-3": "translate.eu-west-3.amazonaws.com",
      "cn-north-1": "translate.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "translate.sa-east-1.amazonaws.com",
      "eu-west-1": "translate.eu-west-1.amazonaws.com",
      "us-gov-west-1": "translate.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "translate.ap-southeast-2.amazonaws.com",
      "ca-central-1": "translate.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "translate"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DeleteTerminology_605927 = ref object of OpenApiRestCall_605589
proc url_DeleteTerminology_605929(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTerminology_605928(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## A synchronous action that deletes a custom terminology.
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
      "AWSShineFrontendService_20170701.DeleteTerminology"))
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

proc call*(call_606085: Call_DeleteTerminology_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A synchronous action that deletes a custom terminology.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_DeleteTerminology_605927; body: JsonNode): Recallable =
  ## deleteTerminology
  ## A synchronous action that deletes a custom terminology.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var deleteTerminology* = Call_DeleteTerminology_605927(name: "deleteTerminology",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.DeleteTerminology",
    validator: validate_DeleteTerminology_605928, base: "/",
    url: url_DeleteTerminology_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTextTranslationJob_606196 = ref object of OpenApiRestCall_605589
proc url_DescribeTextTranslationJob_606198(protocol: Scheme; host: string;
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

proc validate_DescribeTextTranslationJob_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with an asycnhronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
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
      "AWSShineFrontendService_20170701.DescribeTextTranslationJob"))
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

proc call*(call_606208: Call_DescribeTextTranslationJob_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with an asycnhronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_DescribeTextTranslationJob_606196; body: JsonNode): Recallable =
  ## describeTextTranslationJob
  ## Gets the properties associated with an asycnhronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var describeTextTranslationJob* = Call_DescribeTextTranslationJob_606196(
    name: "describeTextTranslationJob", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.DescribeTextTranslationJob",
    validator: validate_DescribeTextTranslationJob_606197, base: "/",
    url: url_DescribeTextTranslationJob_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminology_606211 = ref object of OpenApiRestCall_605589
proc url_GetTerminology_606213(protocol: Scheme; host: string; base: string;
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

proc validate_GetTerminology_606212(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a custom terminology.
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
      "AWSShineFrontendService_20170701.GetTerminology"))
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

proc call*(call_606223: Call_GetTerminology_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a custom terminology.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_GetTerminology_606211; body: JsonNode): Recallable =
  ## getTerminology
  ## Retrieves a custom terminology.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var getTerminology* = Call_GetTerminology_606211(name: "getTerminology",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.GetTerminology",
    validator: validate_GetTerminology_606212, base: "/", url: url_GetTerminology_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportTerminology_606226 = ref object of OpenApiRestCall_605589
proc url_ImportTerminology_606228(protocol: Scheme; host: string; base: string;
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

proc validate_ImportTerminology_606227(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates or updates a custom terminology, depending on whether or not one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. Currently, the only supported merge strategy is OVERWRITE, and so the imported terminology will overwrite an existing terminology of the same name.</p> <p>If you import a terminology that overwrites an existing one, the new terminology take up to 10 minutes to fully propagate and be available for use in a translation due to cache policies with the DataPlane service that performs the translations.</p>
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
      "AWSShineFrontendService_20170701.ImportTerminology"))
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

proc call*(call_606238: Call_ImportTerminology_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a custom terminology, depending on whether or not one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. Currently, the only supported merge strategy is OVERWRITE, and so the imported terminology will overwrite an existing terminology of the same name.</p> <p>If you import a terminology that overwrites an existing one, the new terminology take up to 10 minutes to fully propagate and be available for use in a translation due to cache policies with the DataPlane service that performs the translations.</p>
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_ImportTerminology_606226; body: JsonNode): Recallable =
  ## importTerminology
  ## <p>Creates or updates a custom terminology, depending on whether or not one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. Currently, the only supported merge strategy is OVERWRITE, and so the imported terminology will overwrite an existing terminology of the same name.</p> <p>If you import a terminology that overwrites an existing one, the new terminology take up to 10 minutes to fully propagate and be available for use in a translation due to cache policies with the DataPlane service that performs the translations.</p>
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var importTerminology* = Call_ImportTerminology_606226(name: "importTerminology",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.ImportTerminology",
    validator: validate_ImportTerminology_606227, base: "/",
    url: url_ImportTerminology_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTerminologies_606241 = ref object of OpenApiRestCall_605589
proc url_ListTerminologies_606243(protocol: Scheme; host: string; base: string;
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

proc validate_ListTerminologies_606242(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Provides a list of custom terminologies associated with your account.
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
  var valid_606244 = query.getOrDefault("MaxResults")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "MaxResults", valid_606244
  var valid_606245 = query.getOrDefault("NextToken")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "NextToken", valid_606245
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
  var valid_606246 = header.getOrDefault("X-Amz-Target")
  valid_606246 = validateParameter(valid_606246, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.ListTerminologies"))
  if valid_606246 != nil:
    section.add "X-Amz-Target", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Signature")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Signature", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Content-Sha256", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Date")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Date", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Credential")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Credential", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Security-Token")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Security-Token", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Algorithm")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Algorithm", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-SignedHeaders", valid_606253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606255: Call_ListTerminologies_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of custom terminologies associated with your account.
  ## 
  let valid = call_606255.validator(path, query, header, formData, body)
  let scheme = call_606255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606255.url(scheme.get, call_606255.host, call_606255.base,
                         call_606255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606255, url, valid)

proc call*(call_606256: Call_ListTerminologies_606241; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTerminologies
  ## Provides a list of custom terminologies associated with your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606257 = newJObject()
  var body_606258 = newJObject()
  add(query_606257, "MaxResults", newJString(MaxResults))
  add(query_606257, "NextToken", newJString(NextToken))
  if body != nil:
    body_606258 = body
  result = call_606256.call(nil, query_606257, nil, nil, body_606258)

var listTerminologies* = Call_ListTerminologies_606241(name: "listTerminologies",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.ListTerminologies",
    validator: validate_ListTerminologies_606242, base: "/",
    url: url_ListTerminologies_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTextTranslationJobs_606260 = ref object of OpenApiRestCall_605589
proc url_ListTextTranslationJobs_606262(protocol: Scheme; host: string; base: string;
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

proc validate_ListTextTranslationJobs_606261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the batch translation jobs that you have submitted.
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
  var valid_606263 = query.getOrDefault("MaxResults")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "MaxResults", valid_606263
  var valid_606264 = query.getOrDefault("NextToken")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "NextToken", valid_606264
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
  var valid_606265 = header.getOrDefault("X-Amz-Target")
  valid_606265 = validateParameter(valid_606265, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.ListTextTranslationJobs"))
  if valid_606265 != nil:
    section.add "X-Amz-Target", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Signature")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Signature", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Content-Sha256", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Date")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Date", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Credential")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Credential", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Security-Token")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Security-Token", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Algorithm")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Algorithm", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-SignedHeaders", valid_606272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606274: Call_ListTextTranslationJobs_606260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the batch translation jobs that you have submitted.
  ## 
  let valid = call_606274.validator(path, query, header, formData, body)
  let scheme = call_606274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606274.url(scheme.get, call_606274.host, call_606274.base,
                         call_606274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606274, url, valid)

proc call*(call_606275: Call_ListTextTranslationJobs_606260; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTextTranslationJobs
  ## Gets a list of the batch translation jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606276 = newJObject()
  var body_606277 = newJObject()
  add(query_606276, "MaxResults", newJString(MaxResults))
  add(query_606276, "NextToken", newJString(NextToken))
  if body != nil:
    body_606277 = body
  result = call_606275.call(nil, query_606276, nil, nil, body_606277)

var listTextTranslationJobs* = Call_ListTextTranslationJobs_606260(
    name: "listTextTranslationJobs", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.ListTextTranslationJobs",
    validator: validate_ListTextTranslationJobs_606261, base: "/",
    url: url_ListTextTranslationJobs_606262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTextTranslationJob_606278 = ref object of OpenApiRestCall_605589
proc url_StartTextTranslationJob_606280(protocol: Scheme; host: string; base: string;
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

proc validate_StartTextTranslationJob_606279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts an asynchronous batch translation job. Batch translation jobs can be used to translate large volumes of text across multiple documents at once. For more information, see <a>async</a>.</p> <p>Batch translation jobs can be described with the <a>DescribeTextTranslationJob</a> operation, listed with the <a>ListTextTranslationJobs</a> operation, and stopped with the <a>StopTextTranslationJob</a> operation.</p> <note> <p>Amazon Translate does not support batch translation of multiple source languages at once.</p> </note>
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
  var valid_606281 = header.getOrDefault("X-Amz-Target")
  valid_606281 = validateParameter(valid_606281, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.StartTextTranslationJob"))
  if valid_606281 != nil:
    section.add "X-Amz-Target", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Signature")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Signature", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Content-Sha256", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Date")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Date", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Credential")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Credential", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Security-Token")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Security-Token", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Algorithm")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Algorithm", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-SignedHeaders", valid_606288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606290: Call_StartTextTranslationJob_606278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an asynchronous batch translation job. Batch translation jobs can be used to translate large volumes of text across multiple documents at once. For more information, see <a>async</a>.</p> <p>Batch translation jobs can be described with the <a>DescribeTextTranslationJob</a> operation, listed with the <a>ListTextTranslationJobs</a> operation, and stopped with the <a>StopTextTranslationJob</a> operation.</p> <note> <p>Amazon Translate does not support batch translation of multiple source languages at once.</p> </note>
  ## 
  let valid = call_606290.validator(path, query, header, formData, body)
  let scheme = call_606290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606290.url(scheme.get, call_606290.host, call_606290.base,
                         call_606290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606290, url, valid)

proc call*(call_606291: Call_StartTextTranslationJob_606278; body: JsonNode): Recallable =
  ## startTextTranslationJob
  ## <p>Starts an asynchronous batch translation job. Batch translation jobs can be used to translate large volumes of text across multiple documents at once. For more information, see <a>async</a>.</p> <p>Batch translation jobs can be described with the <a>DescribeTextTranslationJob</a> operation, listed with the <a>ListTextTranslationJobs</a> operation, and stopped with the <a>StopTextTranslationJob</a> operation.</p> <note> <p>Amazon Translate does not support batch translation of multiple source languages at once.</p> </note>
  ##   body: JObject (required)
  var body_606292 = newJObject()
  if body != nil:
    body_606292 = body
  result = call_606291.call(nil, nil, nil, nil, body_606292)

var startTextTranslationJob* = Call_StartTextTranslationJob_606278(
    name: "startTextTranslationJob", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.StartTextTranslationJob",
    validator: validate_StartTextTranslationJob_606279, base: "/",
    url: url_StartTextTranslationJob_606280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTextTranslationJob_606293 = ref object of OpenApiRestCall_605589
proc url_StopTextTranslationJob_606295(protocol: Scheme; host: string; base: string;
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

proc validate_StopTextTranslationJob_606294(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops an asynchronous batch translation job that is in progress.</p> <p>If the job's state is <code>IN_PROGRESS</code>, the job will be marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state. Otherwise, the job is put into the <code>STOPPED</code> state.</p> <p>Asynchronous batch translation jobs are started with the <a>StartTextTranslationJob</a> operation. You can use the <a>DescribeTextTranslationJob</a> or <a>ListTextTranslationJobs</a> operations to get a batch translation job's <code>JobId</code>.</p>
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
  var valid_606296 = header.getOrDefault("X-Amz-Target")
  valid_606296 = validateParameter(valid_606296, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.StopTextTranslationJob"))
  if valid_606296 != nil:
    section.add "X-Amz-Target", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Signature")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Signature", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Content-Sha256", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Date")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Date", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Credential")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Credential", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Security-Token")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Security-Token", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Algorithm")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Algorithm", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-SignedHeaders", valid_606303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606305: Call_StopTextTranslationJob_606293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an asynchronous batch translation job that is in progress.</p> <p>If the job's state is <code>IN_PROGRESS</code>, the job will be marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state. Otherwise, the job is put into the <code>STOPPED</code> state.</p> <p>Asynchronous batch translation jobs are started with the <a>StartTextTranslationJob</a> operation. You can use the <a>DescribeTextTranslationJob</a> or <a>ListTextTranslationJobs</a> operations to get a batch translation job's <code>JobId</code>.</p>
  ## 
  let valid = call_606305.validator(path, query, header, formData, body)
  let scheme = call_606305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606305.url(scheme.get, call_606305.host, call_606305.base,
                         call_606305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606305, url, valid)

proc call*(call_606306: Call_StopTextTranslationJob_606293; body: JsonNode): Recallable =
  ## stopTextTranslationJob
  ## <p>Stops an asynchronous batch translation job that is in progress.</p> <p>If the job's state is <code>IN_PROGRESS</code>, the job will be marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state. Otherwise, the job is put into the <code>STOPPED</code> state.</p> <p>Asynchronous batch translation jobs are started with the <a>StartTextTranslationJob</a> operation. You can use the <a>DescribeTextTranslationJob</a> or <a>ListTextTranslationJobs</a> operations to get a batch translation job's <code>JobId</code>.</p>
  ##   body: JObject (required)
  var body_606307 = newJObject()
  if body != nil:
    body_606307 = body
  result = call_606306.call(nil, nil, nil, nil, body_606307)

var stopTextTranslationJob* = Call_StopTextTranslationJob_606293(
    name: "stopTextTranslationJob", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.StopTextTranslationJob",
    validator: validate_StopTextTranslationJob_606294, base: "/",
    url: url_StopTextTranslationJob_606295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TranslateText_606308 = ref object of OpenApiRestCall_605589
proc url_TranslateText_606310(protocol: Scheme; host: string; base: string;
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

proc validate_TranslateText_606309(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Translates input text from the source language to the target language. For a list of available languages and language codes, see <a>what-is-languages</a>.
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
  var valid_606311 = header.getOrDefault("X-Amz-Target")
  valid_606311 = validateParameter(valid_606311, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.TranslateText"))
  if valid_606311 != nil:
    section.add "X-Amz-Target", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Signature")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Signature", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Content-Sha256", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Date")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Date", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Credential")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Credential", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Security-Token")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Security-Token", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Algorithm")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Algorithm", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-SignedHeaders", valid_606318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_TranslateText_606308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Translates input text from the source language to the target language. For a list of available languages and language codes, see <a>what-is-languages</a>.
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_TranslateText_606308; body: JsonNode): Recallable =
  ## translateText
  ## Translates input text from the source language to the target language. For a list of available languages and language codes, see <a>what-is-languages</a>.
  ##   body: JObject (required)
  var body_606322 = newJObject()
  if body != nil:
    body_606322 = body
  result = call_606321.call(nil, nil, nil, nil, body_606322)

var translateText* = Call_TranslateText_606308(name: "translateText",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.TranslateText",
    validator: validate_TranslateText_606309, base: "/", url: url_TranslateText_606310,
    schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
